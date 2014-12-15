# encoding: utf-8
require 'active_support/concern'

module LogModule
  extend ActiveSupport::Concern

  def log_changes(action_id, user_id)

    if user_id
      username = User.find(user_id).username
    else
      # si connexion via le portail famille
      username = "Famille:" + self.enfant.famille.nom    
    end

    changes = if action_id == 2 
      then self.inspect 
      else self.changes 
    end

    if changes.include?(:famille_id)
      changes[:famille_id] = Famille.find(changes[:famille_id].last).nom
    end

    if changes.include?(:tarif_id)
      changes[:tarif_id] = Tarif.find(changes[:tarif_id].last).memo
    end

    quoi = case self.class.name
      when 'Famille' then "Famille:#{Famille.find(self.id).nom}"
      when 'Enfant' then "Enfant:#{Famille.find(self.famille_id).nom} #{Enfant.find(self.id).prenom}"
      when 'Prestation' then "Prestation:#{self.date} Enfant:#{Enfant.find(self.enfant_id).famille.nom} #{Enfant.find(self.enfant_id).prenom}"
      when 'Facture' then "Facture:#{self.ref} Famille:#{Famille.find(self.famille_id).nom}"
      when 'Paiement' then "Paiement:#{self.ref} Famille:#{Famille.find(self.famille_id).nom}"
      when 'Ville' then "Coordonnées/Paramètres:#{self.nom}"
      when 'Classroom' then "Classe:#{self.nom}"
      when 'Vacance' then "Vacance:#{self.nom}"
      when 'Tarif' then "Tarif:#{self.memo}"
      when 'User' then "Utilisateur:#{self.username}"
    end

    # converti les valeurs numériques décimales en texte
    txt = ""
    changes.each do |change|
      key = change.first  
      values = change.last
      if values.first != values.last
        txt << key + ":"
        txt << values.first.to_s
        txt << "=>"
        txt << values.last.to_s
        txt << " "
      end
    end

    unless txt.blank?
      Log.create(user_id:user_id, qui:username, action_id:action_id, quoi:quoi, msg:txt)	
    end
  end

end

