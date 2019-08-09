# encoding: utf-8
require 'concerns/logmodule.rb'

class Vacance < ApplicationRecord
	include LogModule

	belongs_to :ville

	validates_presence_of :nom, :debut, :fin, :message => "est obligatoire"

end
