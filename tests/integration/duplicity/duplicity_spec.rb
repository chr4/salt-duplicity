control 'duplicity' do
  title 'should be installed & configured'

  describe file('/etc/apt/sources.list.d/duplicity.list') do
    its('content') { should match /^deb http:\/\/ppa.launchpad.net\/duplicity-team\/duplicity-release-git\/ubuntu / }
  end

  describe package('duplicity') do
    it { should be_installed }
    its('version') { should cmp >= '0.8.13-ppa202005201506~ubuntu18.04.1' }
  end

  # We're testing with an ftp://, s3:// and boto3+s3:// URL, so make sure all needed packages are installed
  describe package('python3-boto3') do
    it { should be_installed }
  end
  describe package('python3-boto') do
    it { should be_installed }
  end
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
  end

  describe 'multi.json file validation' do
    let(:json_file) { File.read('/etc/duplicity/multi.json') }
    let(:parsed_json) { JSON.parse(json_file) }
    let(:expected_json_string) { <<~JSON
      [
        {
          "description": "Main AWS S3 bucket",
          "url": "boto3+s3://main-backup/subdir",
          "env": [
            {
            "name" : "AWS_ACCESS_KEY_ID",
            "value" : "xyz"
            },
            {
            "name" : "AWS_SECRET_ACCESS_KEY",
            "value" : "bar"
            }
          ]
        },
        {
          "description": "Seconday AWS S3 bucket",
          "url": "s3://secondary-backup/subdir"
        },
        {
          "description": "Any FTP backend",
          "url": "ftp://user:pass@your-server.com/mybackup"
        }
      ]
    JSON
    }
  
    it 'should be valid JSON' do
      expect { parsed_json }.not_to raise_error
    end
  
    it 'should match the expected JSON string' do
      expect(json_file).to eq(expected_json_string)
    end
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
