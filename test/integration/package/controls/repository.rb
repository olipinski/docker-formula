# frozen_string_literal: true

case platform.family
when 'redhat', 'fedora', 'suse'
  os_name_repo_file = {
    'opensuse' => '/etc/zypp/repos.d/docker-ce.repo'
  }
  os_name_repo_file.default = '/etc/yum.repos.d/docker-ce.repo'

  os_name_repo_url = {
    'amazon' => 'https://download.docker.com/linux/centos/7/$basearch/stable',
    'opensuse' => 'https://download.docker.com/linux/sles/$releasever/$basearch/stable'
  }
  # rubocop:disable Metrics/LineLength
  os_name_repo_url.default = "https://download.docker.com/linux/#{platform.name}/$releasever/$basearch/stable"
  # rubocop:enable Metrics/LineLength
  repo_url = os_name_repo_url[platform.name]
  repo_file = os_name_repo_file[platform.name]

when 'debian'
  # Inspec does not provide a `codename` matcher, so we add ours
  finger_codename = {
    'ubuntu-18.04' => 'bionic',
    'ubuntu-20.04' => 'focal',
    'debian-9' => 'stretch',
    'debian-10' => 'buster',
    'debian-11' => 'bullseye'
  }
  codename = finger_codename[system.platform[:finger]]

  repo_keyring = '/usr/share/keyrings/docker-archive-keyring.gpg'
  repo_file = '/etc/apt/sources.list.d/docker.list'
  # rubocop:disable Metrics/LineLength
  repo_url = "deb [signed-by=#{repo_keyring} arch=amd64] https://download.docker.com/linux/#{platform.name} #{codename} stable"
  # rubocop:enable Metrics/LineLength
end

control 'Docker repository keyring' do
  title 'should be installed'

  only_if('Requirement for Debian family') do
    os.debian?
  end

  describe file(repo_keyring) do
    it { should exist }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
  end
end

control 'Docker repository' do
  impact 1
  title 'should be configured'
  describe file(repo_file) do
    its('content') { should include repo_url }
  end
end
