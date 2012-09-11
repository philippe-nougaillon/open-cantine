class AddEnvoyeeToFacture < ActiveRecord::Migration
  def change
	add_column :factures, :envoyee, :datetime
  end
end
