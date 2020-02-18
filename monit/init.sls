/usr/local/bin/duplicity-monit:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://{{ tpldir }}/duplicity-monit.jinja
    - template: jinja
    - defaults:
      max_backup_age: {{ pillar['duplicity']['max_backup_age']|default(172800) }}
