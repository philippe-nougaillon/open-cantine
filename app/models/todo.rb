class Todo < ApplicationRecord

	# attr_protected :id

	belongs_to :mairie

	validates_presence_of :description, :message => "manquante"

end
