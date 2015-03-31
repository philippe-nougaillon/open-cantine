# encoding: utf-8

require 'csv'

namespace :familles do

  desc 'Import des familles'	   
  task :import, [:file_path, :save, :user_id] => [:environment] do |t, args|
  	
  	nbre_lignes = nbre_nouveaux = nbre_modifies = nbre_enfants = nbre_enfants_modifies = 0
  	user_id = args.user_id
  	mairie_id = User.find(user_id).mairie_id

  	CSV.foreach(args.file_path, headers:true, col_sep:';', quote_char:'"', encoding:'iso-8859-1:UTF-8') do |row|
  		csv_rows = row.to_hash.slice("Civilité", "Nom", "Adresse", "Adresse2", "CP", "Ville", "Email", "Téléphone", "Portable1", "Portable2", "N°Allocataire", "Mémo", "Nom du Tarif")
  		
		@famille = Famille.where(mairie_id:mairie_id, nom:csv_rows["Nom"]).first
  		unless @famille
			@famille = Famille.new(mairie_id:mairie_id, nom:csv_rows["Nom"])		
		end		
		@famille.civilité = csv_rows['Civilité']
		@famille.adresse = csv_rows['Adresse']
		@famille.adresse2 = csv_rows['Adresse2']
		@famille.cp = csv_rows['CP']
		@famille.ville = csv_rows['Ville']
		@famille.email = csv_rows['Email']
		@famille.phone = csv_rows['Téléphone']
		@famille.mobile1 = csv_rows['Portable1']
		@famille.mobile2 = csv_rows['Portable2']
		@famille.allocataire = csv_rows['N°Allocataire']
		@famille.memo = csv_rows['Mémo']

		unless csv_rows["Nom du Tarif"].blank?
			@tarif = Tarif.where(mairie_id:mairie_id, memo:csv_rows["Nom du Tarif"]).first
			if @tarif
				@famille.tarif_id = @tarif.id
			else
				puts "#{csv_rows["Nom"]} => Tarif inconnu (#{csv_rows["Nom du Tarif"]}) !"
			end
		end
		
		if @famille.new_record?
			if @famille.valid?
		  		puts "#{csv_rows["Nom"]} => AJOUT : #{@famille.changes}"
		  		@famille.log_changes(0, user_id)
		  		nbre_nouveaux += 1 
			else
		  		puts "#{csv_rows["Nom"]} => ERREUR AJOUT : #{@famille.errors.full_messages}" 
			end
		else
			if @famille.changes.any?
		  		puts "#{csv_rows["Nom"]} => MAJ : #{@famille.changes}"
		  		@famille.log_changes(1, user_id)
		  		nbre_modifies += 1
		  	end 
		end
		@famille.save if args.save == 'true'

		# enfant

		csv_rows = row.to_hash.slice("Enfant_Nom", "Enfant_Prénom", "Enfant_Date_de_naissance", "Enfant_Classe", "Enfant_Nom_du_Tarif")
  		@enfant = @famille.enfants.where(prenom:csv_rows["Enfant_Prénom"]).first
  		unless @enfant
  			@enfant = @famille.enfants.new(prenom:csv_rows["Enfant_Prénom"])
  		end
  		@enfant.nomfamille =  csv_rows["Enfant_Nom"]
  		@enfant.dateNaissance = csv_rows["Enfant_Date_de_naissance"]

  		unless csv_rows["Enfant_Nom_du_Tarif"].blank?
			@tarif = Tarif.where(mairie_id:mairie_id, memo:csv_rows["Enfant_Nom_du_Tarif"]).first
			if @tarif
				@enfant.tarif_id = @tarif.id
			else
				puts "#{csv_rows["Enfant_Nom"]} #{csv_rows["Enfant_Prénom"]} => Tarif inconnu (#{csv_rows["Enfant_Nom_du_Tarif"]}) !"
			end
		end

  		unless csv_rows["Enfant_Classe"].blank?
			@classe = Classroom.where(mairie_id:mairie_id, nom:csv_rows["Enfant_Classe"]).first
			if @classe
				@enfant.classe = @classe.id
			else
				puts "#{csv_rows["Enfant_Nom"]} #{csv_rows["Enfant_Prénom"]} => Tarif inconnu (#{csv_rows["Enfant_Nom_du_Tarif"]}) !"
			end
		end

		if @enfant.new_record?
			if @enfant.valid?
		  		puts "#{csv_rows["Enfant_Nom"]} #{csv_rows["Enfant_Prénom"]} => AJOUT : #{@enfant.changes}"
		  		@enfant.log_changes(0, user_id)
		  		nbre_enfants += 1 
			else
		  		puts "#{csv_rows["Enfant_Nom"]} #{csv_rows["Enfant_Prénom"]} => ERREUR AJOUT : #{@enfant.errors.full_messages} #{@enfant.changes}" 
			end
		else
			if @enfant.changes.any?
		  		puts "#{csv_rows["Enfant_Nom"]} #{csv_rows["Enfant_Prénom"]} => MAJ : #{@enfant.changes}"
		  		@enfant.log_changes(1, user_id)
		  		nbre_enfants_modifies += 1
		  	end 
		end
		nbre_lignes += 1
		@enfant.save if args.save == 'true'
		puts
  	end

  	puts
  	puts "-" * 220
  	puts "Nbre de lignes:#{nbre_lignes} / Nbre de nouvelles familles:#{nbre_nouveaux} / Nbre de mise à jour:#{nbre_modifies} / Nbre d'inchangés:#{nbre_lignes - (nbre_modifies + nbre_nouveaux)} / Nbre d'enfants ajoutés:#{nbre_enfants} / Nbre d'enfants modifiés:#{nbre_enfants_modifies}"
  	puts "-" * 220
  end

end
