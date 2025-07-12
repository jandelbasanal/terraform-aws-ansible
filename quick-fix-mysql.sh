#!/bin/bash
# Simple MySQL fallback fix

echo "🔧 MySQL Quick Fix - Fallback to Ubuntu Default"
echo "==============================================="

echo "📝 Creating simplified MySQL installation..."

# Backup original MySQL main.yml
if [ -f "ansible/roles/mysql/tasks/main.yml" ]; then
    cp ansible/roles/mysql/tasks/main.yml ansible/roles/mysql/tasks/main.yml.backup
    echo "✅ Backed up original MySQL main.yml"
fi

# Create simplified MySQL installation
cat > ansible/roles/mysql/tasks/main-simple.yml << 'EOF'
---
# Simplified MySQL installation using Ubuntu default repositories
- name: Check if MySQL is already installed
  command: mysql --version
  register: mysql_current_version
  failed_when: false
  changed_when: false

- name: Display current MySQL status
  debug:
    msg: "MySQL Status: {{ 'Already installed - ' + mysql_current_version.stdout if mysql_current_version.rc == 0 else 'Not installed, will install from Ubuntu repositories' }}"

- name: Install MySQL server (Ubuntu default)
  apt:
    name:
      - mysql-server
      - mysql-client
      - python3-pymysql
    state: present
    update_cache: yes

- name: Verify MySQL installation
  command: mysql --version
  register: mysql_verify
  failed_when: mysql_verify.rc != 0
  changed_when: false

- name: Display installed MySQL version
  debug:
    msg: "Installed MySQL version: {{ mysql_verify.stdout }}"

- name: Start and enable MySQL service
  systemd:
    name: mysql
    state: started
    enabled: yes

- name: Set MySQL root password
  mysql_user:
    name: root
    password: "{{ mysql_root_password }}"
    login_unix_socket: /var/run/mysqld/mysqld.sock
    state: present

- name: Create MySQL configuration file for root
  template:
    src: root_my.cnf.j2
    dest: /root/.my.cnf
    owner: root
    group: root
    mode: '0600'

- name: Remove anonymous MySQL users
  mysql_user:
    name: ''
    host_all: yes
    state: absent
    login_user: root
    login_password: "{{ mysql_root_password }}"

- name: Remove MySQL test database
  mysql_db:
    name: test
    state: absent
    login_user: root
    login_password: "{{ mysql_root_password }}"

- name: Create WordPress database
  mysql_db:
    name: "{{ wordpress_db_name }}"
    state: present
    login_user: root
    login_password: "{{ mysql_root_password }}"

- name: Create WordPress database user
  mysql_user:
    name: "{{ wordpress_db_user }}"
    password: "{{ mysql_wordpress_password }}"
    priv: "{{ wordpress_db_name }}.*:ALL"
    state: present
    login_user: root
    login_password: "{{ mysql_root_password }}"
EOF

# Replace with simplified version
cp ansible/roles/mysql/tasks/main-simple.yml ansible/roles/mysql/tasks/main.yml
echo "✅ Switched to simplified MySQL installation"

echo ""
echo "🎉 MySQL Quick Fix Applied Successfully!"
echo "======================================"
echo ""
echo "📋 Changes made:"
echo "✅ MySQL installation now uses Ubuntu default repositories only"
echo "✅ No external MySQL repository dependencies"
echo "✅ Installs MySQL 8.0 from Ubuntu repositories"
echo "✅ All original files backed up with .backup extension"
echo ""
echo "🚀 You can now run the deployment:"
echo "   ./test-mysql-fallback.sh <ssh-key-path>"
echo "   or"
echo "   ./test-ansible.sh <ssh-key-path>"
echo ""
echo "🔄 To restore original files (if needed):"
echo "   cp ansible/roles/mysql/tasks/main.yml.backup ansible/roles/mysql/tasks/main.yml"
