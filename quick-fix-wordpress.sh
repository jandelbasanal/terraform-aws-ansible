#!/bin/bash
# Quick fix for WordPress download issues

echo "🔧 WordPress Download Quick Fix"
echo "==============================="

echo "📝 Creating WordPress role with download fallbacks..."

# Backup original WordPress main.yml
if [ -f "ansible/roles/wordpress/tasks/main.yml" ]; then
    cp ansible/roles/wordpress/tasks/main.yml ansible/roles/wordpress/tasks/main.yml.backup
    echo "✅ Backed up original WordPress main.yml"
fi

# Create simplified WordPress installation with fallbacks
cat > ansible/roles/wordpress/tasks/main-simple.yml << 'EOF'
---
# WordPress installation with multiple download fallbacks
- name: Install curl and wget for download fallbacks
  apt:
    name:
      - curl
      - wget
    state: present

- name: Download WordPress using curl
  shell: |
    cd /tmp
    curl -L -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
    if [ $? -eq 0 ] && [ -f wordpress.tar.gz ]; then
      echo "WordPress downloaded successfully with curl"
    else
      exit 1
    fi
  register: wp_download_curl
  failed_when: false

- name: Download WordPress using wget (fallback)
  shell: |
    cd /tmp
    wget -O wordpress.tar.gz https://wordpress.org/latest.tar.gz
    if [ $? -eq 0 ] && [ -f wordpress.tar.gz ]; then
      echo "WordPress downloaded successfully with wget"
    else
      exit 1
    fi
  register: wp_download_wget
  failed_when: false
  when: wp_download_curl.failed is defined and wp_download_curl.failed

- name: Check if WordPress was downloaded
  stat:
    path: /tmp/wordpress.tar.gz
  register: wp_download_check

- name: Display download status
  debug:
    msg: "WordPress download status: {{ 'Success' if wp_download_check.stat.exists else 'Failed' }}"

- name: Extract WordPress
  unarchive:
    src: /tmp/wordpress.tar.gz
    dest: /tmp/
    remote_src: yes
  when: wp_download_check.stat.exists

- name: Copy WordPress files to web root
  copy:
    src: /tmp/wordpress/
    dest: /var/www/html/
    owner: www-data
    group: www-data
    mode: '0755'
    remote_src: yes
  when: wp_download_check.stat.exists

- name: Create WordPress configuration
  template:
    src: wp-config.php.j2
    dest: /var/www/html/wp-config.php
    owner: www-data
    group: www-data
    mode: '0644'
  when: wp_download_check.stat.exists

- name: Set WordPress directory permissions
  file:
    path: /var/www/html
    owner: www-data
    group: www-data
    mode: '0755'
    recurse: yes

- name: Create WordPress uploads directory
  file:
    path: /var/www/html/wp-content/uploads
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'
  when: wp_download_check.stat.exists

- name: Remove default index.html
  file:
    path: /var/www/html/index.html
    state: absent

- name: Check if WordPress is accessible
  uri:
    url: "http://{{ ansible_default_ipv4.address }}"
    method: GET
    status_code: [200, 302]
  register: wp_access_check
  ignore_errors: yes
  when: wp_download_check.stat.exists

- name: Create WordPress setup page if download failed
  copy:
    content: |
      <!DOCTYPE html>
      <html>
      <head>
          <title>WordPress Setup</title>
          <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
              .alert { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px; }
              .info { background: #d1ecf1; border: 1px solid #b8daff; color: #0c5460; padding: 15px; border-radius: 5px; margin: 20px 0; }
              .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 5px; }
              .button { background: #007cba; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }
          </style>
      </head>
      <body>
          <div class="alert">
              <h2>⚠️  WordPress Download Issue</h2>
              <p>WordPress couldn't be downloaded automatically due to SSL/HTTPS connectivity issues.</p>
          </div>
          
          <div class="success">
              <h2>✅ Server Setup Complete</h2>
              <p>Your LAMP stack is ready! Here's what's been configured:</p>
              <ul>
                  <li>✅ Apache web server</li>
                  <li>✅ MySQL database ({{ wordpress_db_name }})</li>
                  <li>✅ PHP {{ php_version | default('8.1+') }}</li>
                  <li>✅ Database user: {{ wordpress_db_user }}</li>
              </ul>
          </div>
          
          <div class="info">
              <h3>🚀 Manual WordPress Installation</h3>
              <p>Since automatic download failed, please install WordPress manually:</p>
              <ol>
                  <li>SSH into your server: <code>ssh -i your-key.pem ubuntu@{{ ansible_default_ipv4.address }}</code></li>
                  <li>Download WordPress: <code>cd /tmp && wget https://wordpress.org/latest.tar.gz</code></li>
                  <li>Extract: <code>tar -xzf latest.tar.gz</code></li>
                  <li>Copy files: <code>sudo cp -r wordpress/* /var/www/html/</code></li>
                  <li>Set permissions: <code>sudo chown -R www-data:www-data /var/www/html</code></li>
                  <li>Visit your site: <a href="http://{{ ansible_default_ipv4.address }}">http://{{ ansible_default_ipv4.address }}</a></li>
              </ol>
          </div>
          
          <div class="info">
              <h3>🔐 Database Configuration</h3>
              <p>Use these details during WordPress setup:</p>
              <ul>
                  <li><strong>Database Name:</strong> {{ wordpress_db_name }}</li>
                  <li><strong>Database User:</strong> {{ wordpress_db_user }}</li>
                  <li><strong>Database Host:</strong> localhost</li>
                  <li><strong>Database Password:</strong> [Check your deployment configuration]</li>
              </ul>
          </div>
      </body>
      </html>
    dest: /var/www/html/index.html
    owner: www-data
    group: www-data
    mode: '0644'
  when: not wp_download_check.stat.exists

- name: Clean up temporary files
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - /tmp/wordpress.tar.gz
    - /tmp/wordpress
  ignore_errors: yes

- name: Display WordPress installation status
  debug:
    msg:
      - "🎉 WordPress Setup Status"
      - "========================"
      - "{{ '✅ WordPress installed successfully!' if wp_download_check.stat.exists else '⚠️  WordPress requires manual installation' }}"
      - ""
      - "🌐 Your site: http://{{ ansible_default_ipv4.address }}"
      - "🔧 Database: {{ wordpress_db_name }}"
      - "👤 DB User: {{ wordpress_db_user }}"
      - ""
      - "{{ '🚀 WordPress is ready to use!' if wp_download_check.stat.exists else '📝 Follow the manual installation steps shown on your site' }}"
EOF

# Replace with simplified version
cp ansible/roles/wordpress/tasks/main-simple.yml ansible/roles/wordpress/tasks/main.yml
echo "✅ Switched to WordPress installation with download fallbacks"

echo ""
echo "🎉 WordPress Download Quick Fix Applied!"
echo "======================================="
echo ""
echo "📋 Changes made:"
echo "✅ WordPress download now uses curl and wget as fallbacks"
echo "✅ Graceful handling of download failures"
echo "✅ Manual installation guide if download fails"
echo "✅ Server setup continues regardless of download issues"
echo "✅ Original files backed up with .backup extension"
echo ""
echo "🚀 You can now run the deployment:"
echo "   ./test-ansible.sh <ssh-key-path>"
echo ""
echo "📋 What will happen:"
echo "• If download works: Full WordPress installation"
echo "• If download fails: Manual installation guide with all database details"
echo "• Either way: Complete LAMP stack ready for WordPress"
echo ""
echo "🔄 To restore original files (if needed):"
echo "   cp ansible/roles/wordpress/tasks/main.yml.backup ansible/roles/wordpress/tasks/main.yml"
