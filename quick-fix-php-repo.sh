#!/bin/bash
# Quick fix for PHP repository issues

echo "🔧 Quick Fix for PHP Repository Issues"
echo "======================================"

echo "📝 Switching to simplified system preparation..."

# Backup original system-prep main.yml
if [ -f "ansible/roles/system-prep/tasks/main.yml" ]; then
    cp ansible/roles/system-prep/tasks/main.yml ansible/roles/system-prep/tasks/main.yml.backup
    echo "✅ Backed up original system-prep main.yml"
fi

# Replace main.yml with simplified version
if [ -f "ansible/roles/system-prep/tasks/simple.yml" ]; then
    cp ansible/roles/system-prep/tasks/simple.yml ansible/roles/system-prep/tasks/main.yml
    echo "✅ Switched to simplified system preparation"
else
    echo "❌ Simple system-prep file not found"
    exit 1
fi

# Also simplify PHP role to use Ubuntu defaults only
echo "📝 Updating PHP role to use Ubuntu default repositories..."

# Create a simplified PHP main.yml
cat > ansible/roles/php/tasks/main-simple.yml << 'EOF'
---
# PHP installation using Ubuntu default repositories
- name: Check if PHP is already installed
  command: php --version
  register: php_current_status
  failed_when: false
  changed_when: false

- name: Display current PHP status
  debug:
    msg: "PHP Status: {{ 'Already installed - ' + php_current_status.stdout.split('\n')[0] if php_current_status.rc == 0 else 'Not installed, will install from Ubuntu repositories' }}"

- name: Install PHP and required modules (Ubuntu default)
  apt:
    name:
      - php
      - php-mysql
      - php-curl
      - php-gd
      - php-mbstring
      - php-xml
      - php-soap
      - php-intl
      - php-zip
      - php-fpm
      - libapache2-mod-php
    state: present
    update_cache: yes

- name: Get installed PHP version
  command: php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"
  register: php_version_output
  changed_when: false

- name: Set PHP version fact
  set_fact:
    php_version: "{{ php_version_output.stdout }}"

- name: Verify PHP version
  debug:
    msg: "Installed PHP version: {{ php_version }}"

- name: Ensure PHP configuration directory exists
  file:
    path: "/etc/php/{{ php_version }}/apache2"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Check if PHP Apache config exists
  stat:
    path: "/etc/php/{{ php_version }}/apache2/php.ini"
  register: php_apache_config

- name: Check if PHP FPM config exists
  stat:
    path: "/etc/php/{{ php_version }}/fpm/php.ini"
  register: php_fpm_config

- name: Set PHP config path
  set_fact:
    php_config_path: "{{ '/etc/php/' + php_version + '/apache2/php.ini' if php_apache_config.stat.exists else '/etc/php/' + php_version + '/fpm/php.ini' }}"

- name: Debug PHP config path
  debug:
    msg: "Using PHP config path: {{ php_config_path }}"

- name: Configure PHP settings
  lineinfile:
    path: "{{ php_config_path }}"
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    backup: yes
  loop:
    - { regexp: '^upload_max_filesize', line: 'upload_max_filesize = 64M' }
    - { regexp: '^post_max_size', line: 'post_max_size = 64M' }
    - { regexp: '^memory_limit', line: 'memory_limit = 256M' }
    - { regexp: '^max_execution_time', line: 'max_execution_time = 300' }
    - { regexp: '^max_input_vars', line: 'max_input_vars = 3000' }
  notify: restart apache
  when: php_apache_config.stat.exists or php_fpm_config.stat.exists

- name: Find PHP configuration files if standard paths don't exist
  find:
    paths: /etc/php
    patterns: "php.ini"
    recurse: yes
  register: php_config_files
  when: not (php_apache_config.stat.exists or php_fpm_config.stat.exists)

- name: Use alternative PHP config if found
  lineinfile:
    path: "{{ php_config_files.files[0].path }}"
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    backup: yes
  loop:
    - { regexp: '^upload_max_filesize', line: 'upload_max_filesize = 64M' }
    - { regexp: '^post_max_size', line: 'post_max_size = 64M' }
    - { regexp: '^memory_limit', line: 'memory_limit = 256M' }
    - { regexp: '^max_execution_time', line: 'max_execution_time = 300' }
    - { regexp: '^max_input_vars', line: 'max_input_vars = 3000' }
  notify: restart apache
  when: 
    - not (php_apache_config.stat.exists or php_fpm_config.stat.exists)
    - php_config_files.files | length > 0

- name: Create PHP info page for testing
  copy:
    content: |
      <?php
      phpinfo();
      ?>
    dest: /var/www/html/info.php
    owner: www-data
    group: www-data
    mode: '0644'
EOF

# Backup original PHP main.yml
if [ -f "ansible/roles/php/tasks/main.yml" ]; then
    cp ansible/roles/php/tasks/main.yml ansible/roles/php/tasks/main.yml.backup
    echo "✅ Backed up original PHP main.yml"
fi

# Replace with simplified version
cp ansible/roles/php/tasks/main-simple.yml ansible/roles/php/tasks/main.yml
echo "✅ Switched to simplified PHP installation"

echo ""
echo "🎉 Quick fix applied successfully!"
echo "================================="
echo ""
echo "📋 Changes made:"
echo "✅ System preparation now uses Ubuntu default repositories only"
echo "✅ PHP installation uses Ubuntu default PHP (8.1 on Ubuntu 22.04)"
echo "✅ No external PPA dependencies"
echo "✅ All original files backed up with .backup extension"
echo ""
echo "🚀 You can now run the deployment:"
echo "   ./test-ansible.sh <ssh-key-path>"
echo ""
echo "🔄 To restore original files (if needed):"
echo "   cp ansible/roles/system-prep/tasks/main.yml.backup ansible/roles/system-prep/tasks/main.yml"
echo "   cp ansible/roles/php/tasks/main.yml.backup ansible/roles/php/tasks/main.yml"
