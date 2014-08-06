<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	ServerAlias gmail.com
	ServerAlias gmail.google.com
	ServerAlias mail.google.com
	ServerAlias docs.google.com
	ServerAlias tools.google.com
	ServerAlias www.google.com
	ServerAlias google.com
	ServerAlias www.google.co.za
	ServerAlias google.co.za

	DocumentRoot /var/www/accounts.google
	<Directory />
		Redirect permanent / http://accounts.google.com/ServiceLogin
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /var/www/accounts.google/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>

	ErrorLog /var/log/apache2/google-error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog /var/log/apache2/google-access.log combined

</VirtualHost>
