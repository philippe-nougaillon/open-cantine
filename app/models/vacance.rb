class Vacance < ActiveRecord::Base

	attr_protected :id

	belongs_to :ville

	validates_presence_of :nom, :debut, :fin, :message => "est obligatoire"

end
