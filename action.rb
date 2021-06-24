require 'dotenv/load'
require 'octokit'

CONFIG = {
  access_token: ENV['GITHUB_TOKEN'],
  repository: ENV['GITHUB_REPOSITORY'],
  feature_branch: ENV['PULL_REQUEST_FEATURE_BRANCH'],
  base_branch: ENV['PULL_REQUEST_BASE_BRANCH'],
  reviewers: ENV['PULL_REQUEST_REVIEWERS']&.split(','),
  assignees: ENV['PULL_REQUEST_ASSIGNEES']&.split(','),
  labels: ENV['PULL_REQUEST_LABELS']&.split(','),
  accept: 'application/vnd.github.groot-preview+json'
}

def client
  @client ||= Octokit::Client.new(access_token: CONFIG[:access_token])
end

def find_pull_request
  pull_requests = client.pull_requests(CONFIG[:repository])
  pull_requests.find { |pr| pr[:head][:ref] == CONFIG[:feature_branch] && pr[:base][:ref] == CONFIG[:base_branch] }
end

def create_pull_request
  title = "#{CONFIG[:feature_branch]} → #{CONFIG[:base_branch]}"
  pull_request = client.create_pull_request(CONFIG[:repository], CONFIG[:base_branch], CONFIG[:feature_branch], title)
  if CONFIG[:reviewers]&.size&.positive?
    client.request_pull_request_review(CONFIG[:repository], pull_request[:number], reviewers: CONFIG[:reviewers])
  end
  params = { assignees: CONFIG[:assignees], labels: CONFIG[:labels] }.compact
  client.update_issue(CONFIG[:repository], pull_request[:number], params) if params.size.positive?
  pull_request
end

def pull_request_body(pull_request)
  commits = client.pull_request_commits(CONFIG[:repository], pull_request[:number])
  groups = {}
  commits.each do |c|
    pulls = client.commit_pulls(CONFIG[:repository], c[:sha], headers: { accept: CONFIG[:accept]})
    pulls.map do |pr|
      current_group = nil
      pr[:body]&.each_line do |l|
        if l.start_with?('##')
          current_group = l
        elsif l.start_with?('*') && l.strip != '*'
          l << "\r\n" unless l.end_with?("\r\n")

          groups[current_group] ||= []
          groups[current_group] << l
        end
      end
      groups
    end
  end
  body = ''
  groups.each do |k, v|
    body << k
    body << v.uniq.join
  end
  body
end

pull_request = find_pull_request || create_pull_request
client.update_pull_request(CONFIG[:repository], pull_request[:number], body: pull_request_body(pull_request))
