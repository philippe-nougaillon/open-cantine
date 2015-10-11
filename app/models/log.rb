class Log < ActiveRecord::Base
  belongs_to :user

  self.per_page = 20

  def action_name 
	case self.action_id
	  	when 0 then "Ajout"
	  	when 1 then "Modification"
	  	when 2 then "Suppression"
  	end	
  end	

end
