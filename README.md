openCantine
===========

Application web de facturation de cantine

== Installation d'openCantine sur un serveur linux debian

1/ Installation des dépendances au framework Ruby on Rails

sudo apt-get install ruby1.9.1-full
sudo apt-get install ruby1.9.1.dev
sudo apt-get install build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev
sudo apt-get install mysql-server
sudo apt-get install mysql-devel
sudo apt-get install mysql-dev
sudo apt-get install mysql-client libmysqlclient-dev
sudo apt-get install git
sudo apt-get install curl

2/ Installation du framework Ruby on Rails
sudo gem install rails
	sudo gem install therubyracer

3/ Récupération du convertiseur html to PDF
curl -C - -O http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2
	tar xvjf wkhtmltopdf-0.11.0_rc1-static-amd64.tar.bz2
	sudo cp wkhtmltopdf-amd64 /usr/bin/wkhtmltopdf

4/ Récupération des sources depuis la forge Adullact
git clone https://adullact.net/anonscm/git/opencantine/opencantine.git
	cd opencantine
	bundle
	rake db:migrate

5/ Lance le serveur web 
rails s

6/ Et voilà !
rendez-vous sur localhost:3000
Veuillez ensuite à maintenir votre version d'openCantine à jour. 
Pour récupérer les mises à jour depuis la forge adullact :
git pull

