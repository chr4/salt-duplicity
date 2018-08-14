# Install duplicity PPA
duplicity_ppa_repo:
 pkgrepo.managed:
   - name: deb http://ppa.launchpad.net/duplicity-team/ppa/ubuntu {{ grains['oscodename'] }} main
   - file: /etc/apt/sources.list.d/duplicity.list
   - keyid: 7A86F4A2
   - keyserver: keyserver.ubuntu.com
   - require_in:
     - pkg: duplicity

duplicity:
  pkg.installed:
    {% if 'ftp://' in pillar['duplicity']['backend'] %}
    - pkgs: [duplicity, lftp]
    {% elif 's3' in pillar['duplicity']['backend'] %}
    - pkgs: [duplicity, python-boto]
    {% elif 'scp://' in pillar['duplicity']['backend'] %}
    - pkgs: [duplicity, python-paramiko]
    {% endif %}

# Deploy SSH keys
{% if pillar['duplicity']['ssh'] is defined %}
/root/.ssh:
  file.directory:
    - user: root
    - group: root
    - mode: 755

# Append server to ssh_known_hosts
{% if pillar['duplicity']['ssh']['known_hosts'] is defined %}
ssh-keyscan {{ pillar['duplicity']['ssh']['known_hosts'] }} >> /etc/ssh/ssh_known_hosts:
  cmd.run:
    - unless: grep -q {{ pillar['duplicity']['ssh']['known_hosts'] }} /etc/ssh/ssh_known_hosts
{% endif %}

{% for filename in pillar['duplicity']['ssh']['keys'].keys() %}
/root/.ssh/{{ filename }}:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - contents_pillar: duplicity:ssh:keys:{{ filename }}
{% endfor %}
{% endif %}

# Deploy scripts
/usr/local/bin/duplicity-exec:
  file.managed:
    - user: root
    - group: root
    - mode: 700
    - source: salt://{{ slspath }}/duplicity-exec.jinja
    - template: jinja
    - defaults:
      aws_access_key_id: {{ pillar['duplicity']['aws_access_key_id']|default() }}
      aws_secret_access_key: {{ pillar['duplicity']['aws_secret_access_key']|default() }}
      passphrase: {{ pillar['duplicity']['passphrase'] }}
      backend: {{ pillar['duplicity']['backend'] }}

/usr/local/bin/duplicity-take-backup:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://{{ slspath }}/duplicity-take-backup.jinja
    - template: jinja
    - defaults:
      remove_all_but_n_full: {{ pillar['duplicity']['remove_all_but_n_full']|default(5) }}
      full_if_older_than: {{ pillar['duplicity']['full_if_older_than']|default('30D') }}
      include_dirs: {{ pillar['duplicity']['include_dirs']|default(['/etc', '/root']) }}
      exec_pre: {{ pillar['duplicity']['exec_pre']|default([]) }}
      verify: {{ pillar['duplicity']['verify']|default(true) }}

# Install systemd timer and service
/lib/systemd/system/duplicity.service:
  file.managed:
    - source: salt://{{ slspath }}/duplicity.service.jinja
    - template: jinja
    - defaults:
      nice: {{ pillar['duplicity']['nice']|default('10') }}
      io_scheduling_class: {{ pillar['duplicity']['io_scheduling_class']|default('2') }}
      io_scheduling_priority: {{ pillar['duplicity']['io_scheduling_priority']|default('7') }}
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /lib/systemd/system/duplicity.service

duplicity.timer:
  service.running:
    - enable: true
    - watch:
      - file: /lib/systemd/system/duplicity.timer
    - require:
      - file: /lib/systemd/system/duplicity.timer
      - cmd: systemctl daemon-reload
  file.managed:
    - name: /lib/systemd/system/duplicity.timer
    - source: salt://{{ slspath }}/duplicity.timer.jinja
    - template: jinja
    - defaults:
      # Escape on_calendar, as e.g. 23:00 is parsed as 1380 otherwise
      on_calendar: "{{ pillar['duplicity']['on_calendar']|default('02:00') }}"
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /lib/systemd/system/duplicity.timer
