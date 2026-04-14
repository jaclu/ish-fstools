pre_tasks

- name: Decide if sshd should be configured
  set_fact:
  use_sshd: true
  when:
  - (ift_runlevel_sshd | default('') | trim) != ''
  - (ift_port_sshd | default('') | trim) != ''
  - ansible_facts.distribution != 'Debian'
    or (ift_openssh_tgz | default('') | length > 0)

roles - role: common_handlers - role: initial_prep

    # FS specific tasks
    - role: alpine
      when: ansible_facts.distribution == 'Alpine'
    - role: debian
      when: ansible_facts.distribution == 'Debian'
    - role: devuan
      when: ansible_facts.distribution == 'Devuan'

    # FS generic tasks
    - role: all_distros

    # Service handling, first type specific
    - role: openrc
      when: ansible_facts.distribution in ['Alpine', 'Debian']
    - role: sysv_init
      when: ansible_facts.distribution == 'Devuan'
    - role: services # Service handling, common
