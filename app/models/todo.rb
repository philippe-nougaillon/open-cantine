class Todo < ActiveRecord::Base

	attr_protected :id
	validates_presence_of :description, :message => "manquante"

end
