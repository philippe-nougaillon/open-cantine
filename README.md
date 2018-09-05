# openCantine
# Application web de facturation de cantine & activités périscolaires

## Installation sur une instance Gandi Simple Hosting 

### Cloner les sources
git clone https://github.com/philippe-nougaillon/opencantine.git
cd opencantine

### Créer une instance Gandi Simple Hosting (GSH)

Allez sur https://www.gandi.net/fr/simple-hosting afin de créer une instance Ruby/Mysql de taille Small+SSL au minimum. 

Une fois l'instance créée, ouvrez son interface d'administration.
Allez sur "Vue générale/Voir le code deployé" et faite un copier/coller de chaque ligne dans votre répertoire openCantine.  

1/Pour faire pointer votre répertoire source vers l'instance GSH (ici 0000000) :
$ git remote add gandi git+ssh://0000000@git.sd5.gpaas.net/default.git

2/Pour envoyer les sources sur l'instance :
$ git push gandi master

3/Pour déployer les sources et construire l'application :
$ ssh 0000000@git.sd5.gpaas.net deploy default.git
Cette étape peut prendre plusieurs minutes... 

### Créer la base de données

Allez sur "Vue générale/Base de données", cliquez sur "Aller à PhpMyAdmin"
Entrez votre numéro d'instance GSH et votre mot de passe

Une fois dans PhpMyAdmin, connectez-vous avec l'utilisateur 'root' (il n'y a pas de mot de passe)
Cliquez sur 'New' dans le volet de gauche et entrez "OPENCANTINE4.2" dans database name et cliquez sur 'Create'

Retournez sur "Vue générale/Console d'urgence", activez la console et executez la commande de connexion à l'instance :

$ ssh 0000000@console.sd5.gpaas.net

Une fois connecté, executez les commandes suivantes:
$ cd web/vhosts/default/
$ bundle exec rake db:setup


### Créer l'utilisateur admin

Toujours dans la console d'urgence, entrez les commandes suivantes :

$ bundle exec rails c production
irb> Ville.create(nom:"MAIRIE DE PAINPOL", email:"votre email")
irb> User.create(username:"votre adresse email", password:"votre mot de passe", password_salt:"mot secret", readwrite: true, mairie_id: Ville.last.id)

### Associer l'instance à un nom de domaine

Allez dans "Vue générale/Domaine"
Un nom de domaine par défaut a déjà été créé à des fins de test mais vous devez entrez ici le nom de domaine souhaité pour votre instance openCantine. 

### Tester la nouvelle instance
Ouvrez le lien pointant sur le domaine que vous venez de créer et entrez l'identifiant(votre adresse email)/mot de passe de l'utilisateur que nous venons de créer.

Allez dans "Paramètres" pour compléter les informations sur votre mairie et saisir quelques tarifs.

Félicitations, l'installation est terminé !

N'oubliez pas de sécuriser vos données en activant le backup des bases Mysql, comme expliqué dans ce tutoriel : 
https://wiki.gandi.net/fr/simple/anacron


## Installation sur un serveur Linux 
_(Merci à David.G pour ce tuto)

###Pack de base
sudo apt-get update
sudo apt-get install build-essential libssl-dev libyaml-dev libreadline-dev openssl curl git-core zlib1g-dev bison libxml2-dev libxslt1-dev libcurl4-openssl-dev libsqlite3-dev sqlite3

###Installation ruby
mkdir ~/ruby
cd ~/ruby
wget https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.4.tar.gz
tar -xzf ruby-2.2.4.tar.gz
cd ruby-2.2.4
./configure
make
sudo make install

verifier la version installée
ruby -v

###Installation Apache
sudo apt-get install apache2

###Installation Passenger
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
sudo nano /etc/apt/sources.list.d/passenger.list

ajouter cette ligne:
deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main
CTRL+X puis O puis Enter pour sauvegarder

sudo chown root: /etc/apt/sources.list.d/passenger.list
sudo chmod 600 /etc/apt/sources.list.d/passenger.list
sudo apt-get update
sudo apt-get install libapache2-mod-passenger
sudo a2enmod passenger
sudo service apache2 restart
sudo rm /usr/bin/ruby
sudo ln -s /usr/local/bin/ruby /usr/bin/ruby

###Installation Mysql
sudo apt-get install mysql-server
sudo apt-get install libmysqlclient-dev
(vous devrez specifier le mot de passe root de mysql)

###Installation Rails
sudo gem install --no-rdoc --no-ri rails
sudo bundle install

###Récupération sources
cd ~
git clone https://adullact.net/anonscm/git/opencantine/opencantine.git

###Configurer de l'accès à Mysql
cd opencantine
cd config
sudo nano database.yml
(modifier utilisateur root et mot de passe mysql)
CTRL+X puis O puis Enter pour sauvegarder
sudo bundle exec rake db:create db:migrate
A ce stage de l'installation vous pouvez vérifier que Rails est correctement configuré en appelant la console:
rails c
_Si un message d'erreur apparaît, vous avez un problème... passez en revue toutes les étapes précédentes pour identifier le problème avant d'aller plus loin._

###Configurer Virtual host (où myapp est votre app)
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/myapp.conf
sudo nano /etc/apache2/sites-available/myapp.conf

Exemple:

<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    ServerAdmin webmaster@localhost
    DocumentRoot /home/opencantine/public
    RailsEnv development
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    <Directory "/home/opencantine/public">
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>

**(pour utiliser le mode production remplacer development à la ligne RailsEnv)
CTRL+X puis O puis Enter pour sauvegarder**

sudo a2dissite 000-default
sudo a2ensite testapp
sudo service apache2 restart

### Lancement
Lancez votre navigateur à l'adresse localhost

Cliquer sur s'inscrire pour configurer votre openCantine.

EnJoY
