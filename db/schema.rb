# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141031104152) do

  create_table "blogs", :force => true do |t|
    t.string   "titre"
    t.string   "texte"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classes", :force => true do |t|
    t.string   "nom"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classrooms", :force => true do |t|
    t.string   "nom"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "referant"
    t.integer  "mairie_id"
  end

  add_index "classrooms", ["id"], :name => "index_classrooms_on_id"
  add_index "classrooms", ["mairie_id"], :name => "index_classrooms_on_mairie_id"

  create_table "data_files", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "enfants", :force => true do |t|
    t.integer  "famille_id"
    t.string   "prenom"
    t.integer  "age"
    t.integer  "classe"
    t.string   "referant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sansPorc"
    t.boolean  "allergies"
    t.string   "dateNaissance"
    t.integer  "tarif_id"
    t.integer  "habitudeGarderieAM"
    t.integer  "habitudeGarderiePM"
  end

  create_table "facturations", :force => true do |t|
    t.string   "nom"
    t.string   "module"
    t.text     "memo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facture_chronos", :force => true do |t|
    t.integer  "mairie_id"
    t.integer  "prochain"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facture_lignes", :force => true do |t|
    t.integer  "facture_id"
    t.string   "texte"
    t.decimal  "montant",    :precision => 5, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "qte",        :precision => 5, :scale => 2
    t.decimal  "prix",       :precision => 5, :scale => 2
  end

  create_table "factures", :force => true do |t|
    t.integer  "famille_id"
    t.integer  "reglement_id"
    t.string   "ref"
    t.datetime "date"
    t.decimal  "montant",        :precision => 5, :scale => 2
    t.date     "echeance"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mairie_id"
    t.decimal  "SoldeFamille",   :precision => 8, :scale => 2
    t.boolean  "checked"
    t.text     "footer"
    t.decimal  "total_cantine",  :precision => 8, :scale => 2
    t.decimal  "total_garderie", :precision => 8, :scale => 2
    t.decimal  "total_centre",   :precision => 8, :scale => 2
    t.decimal  "total_etude",    :precision => 8, :scale => 2
    t.datetime "envoyee"
  end

  add_index "factures", ["famille_id"], :name => "index_factures_on_famille_id"
  add_index "factures", ["id"], :name => "index_factures_on_id"
  add_index "factures", ["mairie_id"], :name => "index_factures_on_mairie_id"

  create_table "familles", :force => true do |t|
    t.string   "nom"
    t.string   "adresse"
    t.string   "adresse2"
    t.string   "cp"
    t.string   "ville"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
    t.string   "mobile1"
    t.string   "mobile2"
    t.integer  "mairie_id"
    t.string   "civilité"
    t.string   "password"
    t.datetime "lastconnection"
    t.integer  "tarif_id"
    t.text     "memo"
    t.string   "allocataire"
  end

  add_index "familles", ["id"], :name => "index_familles_on_id"
  add_index "familles", ["mairie_id"], :name => "index_familles_on_mairie_id"
  add_index "familles", ["nom"], :name => "index_familles_on_nom"

  create_table "formules", :force => true do |t|
    t.string   "nom"
    t.string   "module_name"
    t.text     "memo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mairies", :force => true do |t|
    t.string   "nom"
    t.string   "adresse"
    t.string   "cp"
    t.string   "ville"
    t.integer  "logo"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tarif2"
    t.boolean  "tarif3"
  end

  create_table "paiements", :force => true do |t|
    t.date     "date"
    t.string   "typepaiement"
    t.string   "ref"
    t.string   "banque"
    t.decimal  "montant",         :precision => 5, :scale => 2, :default => 0.0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "famille_id"
    t.integer  "mairie_id"
    t.decimal  "montantGarderie", :precision => 5, :scale => 2, :default => 0.0, :null => false
    t.decimal  "montantCantine",  :precision => 5, :scale => 2, :default => 0.0, :null => false
    t.date     "remise"
    t.string   "chequenum"
    t.string   "memo"
    t.integer  "facture_id"
  end

  add_index "paiements", ["facture_id"], :name => "index_paiements_on_facture_id"
  add_index "paiements", ["famille_id"], :name => "index_paiements_on_famille_id"
  add_index "paiements", ["id"], :name => "index_paiements_on_id"
  add_index "paiements", ["mairie_id"], :name => "index_paiements_on_mairie_id"

  create_table "paiments", :force => true do |t|
    t.date     "date"
    t.string   "type"
    t.string   "ref"
    t.string   "banque"
    t.decimal  "montant",    :precision => 10, :scale => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prestations", :force => true do |t|
    t.integer  "enfant_id"
    t.integer  "facture_id"
    t.string   "etude",      :limit => 1,                               :default => "0"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "date"
    t.decimal  "totalA",                  :precision => 5, :scale => 2, :default => 0.0, :null => false
    t.decimal  "totalP",                  :precision => 5, :scale => 2
    t.string   "garderieAM",                                            :default => "0"
    t.string   "garderiePM",                                            :default => "0"
    t.string   "centreAM",                                              :default => "0"
    t.string   "centrePM",                                              :default => "0"
    t.string   "repas",      :limit => 1,                               :default => "0"
  end

  add_index "prestations", ["date"], :name => "index_prestations_on_date"
  add_index "prestations", ["enfant_id"], :name => "index_prestations_on_enfant_id"
  add_index "prestations", ["id"], :name => "index_prestations_on_id"

  create_table "tarifs", :force => true do |t|
    t.decimal  "RepasP",      :precision => 5, :scale => 2
    t.decimal  "GarderieAMP", :precision => 5, :scale => 2
    t.decimal  "GarderiePMP", :precision => 5, :scale => 2
    t.decimal  "CentreAMP",   :precision => 5, :scale => 2
    t.decimal  "CentrePMP",   :precision => 5, :scale => 2
    t.decimal  "Etude",       :precision => 5, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "CentreAMPMP", :precision => 5, :scale => 2
    t.integer  "mairie_id"
    t.integer  "type_id"
    t.string   "memo"
  end

  add_index "tarifs", ["id"], :name => "index_tarifs_on_id"
  add_index "tarifs", ["mairie_id"], :name => "index_tarifs_on_mairie_id"

  create_table "todos", :force => true do |t|
    t.string   "description"
    t.integer  "counter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "done",        :default => false
    t.integer  "mairie_id"
    t.string   "note"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password_salt"
    t.string   "password_hash"
    t.integer  "mairie_id"
    t.datetime "lastconnection"
    t.datetime "lastchange"
    t.boolean  "readwrite"
  end

  add_index "users", ["id"], :name => "index_users_on_id"
  add_index "users", ["mairie_id"], :name => "index_users_on_mairie_id"

  create_table "vacances", :force => true do |t|
    t.string   "nom"
    t.date     "debut"
    t.date     "fin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mairie_id"
  end

  add_index "vacances", ["id"], :name => "index_vacances_on_id"
  add_index "vacances", ["mairie_id"], :name => "index_vacances_on_mairie_id"

  create_table "villes", :force => true do |t|
    t.string   "nom"
    t.string   "adr"
    t.string   "cp"
    t.string   "ville"
    t.string   "tel"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tarif2"
    t.boolean  "tarif3"
    t.string   "FacturationModuleName"
    t.string   "email"
    t.boolean  "newsletter"
    t.string   "logo_url"
  end

end
