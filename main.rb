# coding: utf-8

require 'octokit'
require 'open-uri'

class Github
  REPOS = 'hayashima/bondgate'

  def initialize
    Octokit.auto_paginate = true
    @client = Octokit::Client.new(:access_token => ENV['GITHUB_ACCESS_KEY'])
    @request = @client.pull_requests(REPOS).select { |v| v.head.ref == ENV['BRANCH'] }.first
  end

  def notice(status)
    exit unless @request
    case status
      when 'failed'
        failed
      when 'passed'
        passed
      else
        raise 'status not found.'
    end
  end

  private
  def passed
    message = '![](https://raw.githubusercontent.com/hayashima/github_notification/master/img/passed.png)'
    @client.add_comment(REPOS, @request.number, message)
    @client.create_status(REPOS, @request.head.sha, 'success')
  end

  def failed
    message = 'Jenkins build failed.'
    begin
      base_uri = "http://jenkins.bondgate.jp/job/#{ENV['PARENT_JOB_NAME']}/#{ENV['PARENT_BUILD_NUMBER']}/console"
      result = open("#{base_uri}Text",
           :http_basic_authentication=>['github', ENV['JENKINS_PASSWORD']])
      result.read.match(/Failed examples:[\s\S]*/) do |md|
        message = "![](https://raw.githubusercontent.com/hayashima/github_notification/master/img/failed.jpg)\n" +
            md[0].gsub(/#(\d+)/,'＃\1') + "\n\n#{base_uri}"
      end
    rescue OpenURI::HTTPError
      # pass
    end
    @client.add_comment(REPOS, @request.number, message)
    @client.create_status(REPOS, @request.head.sha, 'failure')
  end
end

github = Github.new
github.notice(ENV['STATUS'])