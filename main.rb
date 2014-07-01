require 'octokit'


client = Octokit::Client.new(:access_token => ENV['GITHUB_ACCESS_KEY'])
client.pull_requests('hayashima/bondgate').each do |request|
  p request.head.ref
end