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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160831193354) do

  create_table "blogs", force: :cascade do |t|
    t.string   "titre",      limit: 255
    t.string   "texte",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classes", force: :cascade do |t|
    t.string   "nom",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classrooms", force: :cascade do |t|
    t.string   "nom",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "referant",   limit: 255
    t.integer  "mairie_id",  limit: 4
  end

  add_index "classrooms", ["id"], name: "index_classrooms_on_id", using: :btree
  add_index "classrooms", ["mairie_id"], name: "index_classrooms_on_mairie_id", using: :btree

  create_table "data_files", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "enfants", force: :cascade do |t|
    t.integer  "famille_id",         limit: 4
    t.string   "prenom",             limit: 255
    t.integer  "age",                limit: 4
    t.integer  "classe",             limit: 4
    t.string   "referant",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sansPorc",           limit: 1
    t.boolean  "allergies",          limit: 1
    t.string   "dateNaissance",      limit: 255
    t.integer  "tarif_id",           limit: 4
    t.integer  "habitudeGarderieAM", limit: 4
    t.integer  "habitudeGarderiePM", limit: 4
    t.string   "nomfamille",         limit: 255
  end

  create_table "facturations", force: :cascade do |t|
    t.string   "nom",        limit: 255
    t.string   "module",     limit: 255
    t.text     "memo",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facture_chronos", force: :cascade do |t|
    t.integer  "mairie_id",  limit: 4
    t.integer  "prochain",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facture_lignes", force: :cascade do |t|
    t.integer  "facture_id", limit: 4
    t.string   "texte",      limit: 255
    t.decimal  "montant",                precision: 5, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "qte",                    precision: 5, scale: 2
    t.decimal  "prix",                   precision: 5, scale: 2
  end

  create_table "factures", force: :cascade do |t|
    t.integer  "famille_id",     limit: 4
    t.integer  "reglement_id",   limit: 4
    t.string   "ref",            limit: 255
    t.datetime "date"
    t.decimal  "montant",                      precision: 5, scale: 2
    t.date     "echeance"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mairie_id",      limit: 4
    t.decimal  "SoldeFamille",                 precision: 8, scale: 2
    t.boolean  "checked",        limit: 1
    t.text     "footer",         limit: 65535
    t.decimal  "total_cantine",                precision: 8, scale: 2
    t.decimal  "total_garderie",               precision: 8, scale: 2
    t.decimal  "total_centre",                 precision: 8, scale: 2
    t.decimal  "total_etude",                  precision: 8, scale: 2
    t.datetime "envoyee"
  end

  add_index "factures", ["famille_id"], name: "index_factures_on_famille_id", using: :btree
  add_index "factures", ["id"], name: "index_factures_on_id", using: :btree
  add_index "factures", ["mairie_id"], name: "index_factures_on_mairie_id", using: :btree

  create_table "familles", force: :cascade do |t|
    t.string   "nom",            limit: 255
    t.string   "adresse",        limit: 255
    t.string   "adresse2",       limit: 255
    t.string   "cp",             limit: 255
    t.string   "ville",          limit: 255
    t.string   "email",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone",          limit: 255
    t.string   "mobile1",        limit: 255
    t.string   "mobile2",        limit: 255
    t.integer  "mairie_id",      limit: 4
    t.string   "civilité",       limit: 255
    t.string   "password",       limit: 255
    t.datetime "lastconnection"
    t.integer  "tarif_id",       limit: 4
    t.text     "memo",           limit: 65535
    t.string   "allocataire",    limit: 255
  end

  add_index "familles", ["id"], name: "index_familles_on_id", using: :btree
  add_index "familles", ["mairie_id"], name: "index_familles_on_mairie_id", using: :btree
  add_index "familles", ["nom"], name: "index_familles_on_nom", using: :btree

  create_table "formules", force: :cascade do |t|
    t.string   "nom",         limit: 255
    t.string   "module_name", limit: 255
    t.text     "memo",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", force: :cascade do |t|
    t.string   "qui",        limit: 255
    t.string   "quoi",       limit: 255
    t.text     "msg",        limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "user_id",    limit: 4
    t.integer  "action_id",  limit: 4
  end

  add_index "logs", ["user_id"], name: "index_logs_on_user_id", using: :btree

  create_table "mairies", force: :cascade do |t|
    t.string   "nom",        limit: 255
    t.string   "adresse",    limit: 255
    t.string   "cp",         limit: 255
    t.string   "ville",      limit: 255
    t.integer  "logo",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tarif2",     limit: 1
    t.boolean  "tarif3",     limit: 1
  end

  create_table "paiements", force: :cascade do |t|
    t.date     "date"
    t.string   "typepaiement",    limit: 255
    t.string   "ref",             limit: 255
    t.string   "banque",          limit: 255
    t.decimal  "montant",                     precision: 5, scale: 2, default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "famille_id",      limit: 4
    t.integer  "mairie_id",       limit: 4
    t.decimal  "montantGarderie",             precision: 5, scale: 2, default: 0.0, null: false
    t.decimal  "montantCantine",              precision: 5, scale: 2, default: 0.0, null: false
    t.date     "remise"
    t.string   "chequenum",       limit: 255
    t.string   "memo",            limit: 255
    t.integer  "facture_id",      limit: 4
  end

  add_index "paiements", ["facture_id"], name: "index_paiements_on_facture_id", using: :btree
  add_index "paiements", ["famille_id"], name: "index_paiements_on_famille_id", using: :btree
  add_index "paiements", ["id"], name: "index_paiements_on_id", using: :btree
  add_index "paiements", ["mairie_id"], name: "index_paiements_on_mairie_id", using: :btree

  create_table "paiments", force: :cascade do |t|
    t.date     "date"
    t.string   "type",       limit: 255
    t.string   "ref",        limit: 255
    t.string   "banque",     limit: 255
    t.decimal  "montant",                precision: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prestations", force: :cascade do |t|
    t.integer  "enfant_id",  limit: 4
    t.integer  "facture_id", limit: 4
    t.string   "etude",      limit: 1,                           default: "0"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "date"
    t.decimal  "totalA",                 precision: 5, scale: 2, default: 0.0, null: false
    t.decimal  "totalP",                 precision: 5, scale: 2
    t.string   "garderieAM", limit: 255,                         default: "0"
    t.string   "garderiePM", limit: 255,                         default: "0"
    t.string   "centreAM",   limit: 255,                         default: "0"
    t.string   "centrePM",   limit: 255,                         default: "0"
    t.string   "repas",      limit: 1,                           default: "0"
  end

  add_index "prestations", ["date"], name: "index_prestations_on_date", using: :btree
  add_index "prestations", ["enfant_id"], name: "index_prestations_on_enfant_id", using: :btree
  add_index "prestations", ["id"], name: "index_prestations_on_id", using: :btree

  create_table "tarifs", force: :cascade do |t|
    t.decimal  "RepasP",                  precision: 5, scale: 2
    t.decimal  "GarderieAMP",             precision: 5, scale: 2
    t.decimal  "GarderiePMP",             precision: 5, scale: 2
    t.decimal  "CentreAMP",               precision: 5, scale: 2
    t.decimal  "CentrePMP",               precision: 5, scale: 2
    t.decimal  "Etude",                   precision: 5, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "CentreAMPMP",             precision: 5, scale: 2
    t.integer  "mairie_id",   limit: 4
    t.integer  "type_id",     limit: 4
    t.string   "memo",        limit: 255
  end

  add_index "tarifs", ["id"], name: "index_tarifs_on_id", using: :btree
  add_index "tarifs", ["mairie_id"], name: "index_tarifs_on_mairie_id", using: :btree

  create_table "todos", force: :cascade do |t|
    t.string   "description", limit: 255
    t.integer  "counter",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "done",        limit: 1,   default: false
    t.integer  "mairie_id",   limit: 4
    t.string   "note",        limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",       limit: 255
    t.string   "password_salt",  limit: 255
    t.string   "password_hash",  limit: 255
    t.integer  "mairie_id",      limit: 4
    t.datetime "lastconnection"
    t.datetime "lastchange"
    t.boolean  "readwrite",      limit: 1
  end

  add_index "users", ["id"], name: "index_users_on_id", using: :btree
  add_index "users", ["mairie_id"], name: "index_users_on_mairie_id", using: :btree

  create_table "vacances", force: :cascade do |t|
    t.string   "nom",        limit: 255
    t.date     "debut"
    t.date     "fin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mairie_id",  limit: 4
  end

  add_index "vacances", ["id"], name: "index_vacances_on_id", using: :btree
  add_index "vacances", ["mairie_id"], name: "index_vacances_on_mairie_id", using: :btree

  create_table "villes", force: :cascade do |t|
    t.string   "nom",                   limit: 255
    t.string   "adr",                   limit: 255
    t.string   "cp",                    limit: 255
    t.string   "ville",                 limit: 255
    t.string   "tel",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tarif2",                limit: 1
    t.boolean  "tarif3",                limit: 1
    t.string   "FacturationModuleName", limit: 255
    t.string   "email",                 limit: 255
    t.boolean  "newsletter",            limit: 1
    t.string   "logo_url",              limit: 255
    t.integer  "portail",               limit: 4,   default: 0
  end

end
