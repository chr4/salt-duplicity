control 'duplicity' do
  title 'should be installed & configured'

  describe file('/etc/apt/sources.list.d/duplicity.list') do
    its('content') { should match /^deb http:\/\/ppa.launchpad.net\/duplicity-team\/duplicity-release-git\/ubuntu / }
  end

  describe package('duplicity') do
    it { should be_installed }
    its('version') { should cmp >= '0.8.13-ppa202005201506~ubuntu18.04.1' }
  end

  # We're testing with an ftp:// URL, so make sure lftp is also installed
  #
  # NOTE: We're not testing s3:// and scp:// URLs, they should install python3-boto and
  #       python3-paramiko respectively
  describe package('lftp') do
    it { should be_installed }
  end

  describe file('/etc/ssh/ssh_known_hosts') do
    its('content') { should match /^github.com ssh-rsa AAAA/ }
  end

  describe file('/root/.ssh/id_ed25519') do
    its('content') { should match /-----BEGIN OPENSSH PRIVATE KEY-----/ }
  end

  describe file('/root/.ssh/id_ed25519.pub') do
    its('content') { should match /ssh-ed25519/ }
  end

  describe file('/usr/local/bin/duplicity-exec') do
    its('content') { should match /PASSPHRASE='your-super-secret-passphrase'/ }
    its('content') { should match /AWS_ACCESS_KEY_ID='your-access-key-id'/ }
    its('content') { should match /AWS_SECRET_ACCESS_KEY='your-secret-access-key'/ }
    its('content') { should match /ftp:\/\/user:pass@your-server.com\/mybackup/ }
  end

  describe file('/usr/local/bin/duplicity-take-backup') do
    its('content') { should match /remove-all-but-n-full 5/ }
    its('content') { should match /--full-if-older-than 30D/ }
    its('content') { should match /pg_dumpall/ }
    its('content') { should match /--include '\/root'/ }
    its('content') { should match /--include '\/etc'/ }
    its('content') { should match /cleanup/ }
  end

  describe file('/etc/systemd/system/duplicity.service') do
    its('content') { should match /Nice=10/ }
    its('content') { should match /IOSchedulingClass=2/ }
    its('content') { should match /IOSchedulingPriority=7/ }
  end

  describe file('/etc/systemd/system/duplicity.timer') do
    its('content') { should match /OnCalendar=02:00/ }
  end

  describe service('duplicity.timer') do
    it { should be_enabled }
    it { should be_running }
  end

  describe service('duplicity.service') do
    it { should_not be_running }
  end
end
