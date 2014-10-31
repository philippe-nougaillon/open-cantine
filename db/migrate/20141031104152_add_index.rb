class AddIndex < ActiveRecord::Migration
  def up
  	add_index :users, :id
  	add_index :users, :mairie_id

  	add_index :tarifs, :id
  	add_index :tarifs, :mairie_id

  	add_index :classrooms, :id
  	add_index :classrooms, :mairie_id

  	add_index :vacances, :id
  	add_index :vacances, :mairie_id

  	add_index :familles, :id
  	add_index :familles, :mairie_id
  	add_index :familles, :nom

  	add_index :prestations, :id
  	add_index :prestations, :enfant_id
  	add_index :prestations, :date

  	add_index :factures, :id
  	add_index :factures, :mairie_id
  	add_index :factures, :famille_id

  	add_index :paiements, :id
  	add_index :paiements, :mairie_id
  	add_index :paiements, :famille_id
  	add_index :paiements, :facture_id
  end

  def down
  end
end
