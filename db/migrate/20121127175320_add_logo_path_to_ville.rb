class AddLogoPathToVille < ActiveRecord::Migration
  def change
	add_column :villes, :logo_url, :string
  end
end
