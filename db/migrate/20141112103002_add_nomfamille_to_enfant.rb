class AddNomfamilleToEnfant < ActiveRecord::Migration
  def change
  	add_column :enfants, :nomfamille, :string
  end
end
