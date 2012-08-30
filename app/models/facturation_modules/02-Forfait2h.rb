
module Facturation

  # TARIF A APPLIQUER POUR CETTE PRESTATION
  def Facturation.best_tarif(kid)
      # si tarif forcé dans la fiche enfant
    if kid.tarif_id
        @tarif = Tarif.find(kid.tarif_id)
    else
        if Famille.find(kid.famille_id).tarif_id
           @tarif = Tarif.find(kid.famille.tarif_id) 
	else
           @tarif = Tarif.find(:first, :conditions => ["mairie_id = ?", kid.famille.mairie_id]) 
        end
    end
    return @tarif

  end

  def Facturation.tarif_majore(kid)
    if kid.tarif_id
        # tarif forcé
        tarif_id = Tarif.find(kid.tarif_id).id
    else
      tarif_id = Tarif.find(:first, :conditions => ["mairie_id = ?",  kid.famille.mairie_id]).id 
    end
    return tarif_id
  end


  # Prestations 
  #
  # 0 = Non  
  # 1 = Oui
  # 2 = Annulé par famille
  # 3 = Ajouté par famille
  # 4 = Annulé pour maladie
  # 5 = Garderie 1h
  # 6 = Garderie 1h30
  # 7 = Garderie 2h


 

  def Facturation.calc_prestation(prestations_normales, prestation, tarif, jour)

      # Repas
      if prestation.repas == '1' or prestation.repas == '2' or prestation.repas == '4'
         prestations_normales['MntRepas'] += tarif.RepasP
	 prestations_normales['PrixRepas'] = tarif.RepasP
         prestations_normales['Repas'] += 1
         prestations_normales['JoursRepas'] += "#{jour}, "
      end

      # Garderie
      # ***Spécial*** Garderie 2 fois 1h = 1 forfait 2h
      if prestation.garderieAM == '5' and prestation.garderiePM == '5'
         prestations_normales['MntGarderieAM'] += tarif.GarderieAMP
	 prestations_normales['PrixGarderieAM'] = tarif.GarderieAMP
         prestations_normales['GarderieAM'] += 1
         prestations_normales['JoursGarderieAM'] += "#{jour}, "
      end

      if prestation.garderieAM == '7' or prestation.garderieAM == '1'
         prestations_normales['MntGarderieAM'] += tarif.GarderieAMP
	 prestations_normales['PrixGarderieAM'] = tarif.GarderieAMP
         prestations_normales['GarderieAM'] += 1
         prestations_normales['JoursGarderieAM'] += "#{jour}, "
      end

      if prestation.garderiePM == '7' or prestation.garderiePM == '1' 
         prestations_normales['PrixGarderiePM'] = tarif.GarderiePMP
         prestations_normales['MntGarderiePM'] += tarif.GarderiePMP
         prestations_normales['GarderiePM'] += 1
         prestations_normales['JoursGarderiePM'] += "#{jour}, "
      end

      #Centre
      if (prestation.centreAM == '1' and prestation.centrePM == '1') or (prestation.centreAM == '2' and prestation.centrePM == '2') or (prestation.centreAM == '4' and prestation.centrePM == '4')
         prestations_normales['PrixCentreAMPM'] = tarif.CentreAMPMP
         prestations_normales['MntCentreAMPM'] += tarif.CentreAMPMP
         prestations_normales['CentreAMPM'] += 1
         prestations_normales['JoursCentreAMPM'] += "#{jour}, "
      else
        if prestation.centreAM == '1' or prestation.centreAM == '2' or prestation.centreAM == '4'
           prestations_normales['PrixCentreAM'] = tarif.CentreAMP
           prestations_normales['MntCentreAM'] += tarif.CentreAMP
           prestations_normales['CentreAM'] += 1
           prestations_normales['JoursCentreAM'] += "#{jour}, "
        end
        if prestation.centrePM == '1' or prestation.centrePM == '2' or prestation.centrePM == '4'
           prestations_normales['PrixCentrePM'] += tarif.CentrePMP
           prestations_normales['MntCentrePM'] += tarif.CentrePMP
           prestations_normales['CentrePM'] += 1
           prestations_normales['JoursCentrePM'] += "#{jour}, "
        end
      end

      # Etude
      if prestation.etude == '1'
         prestations_normales['PrixEtude'] = tarif.Etude
         prestations_normales['MntEtude'] += tarif.Etude
         prestations_normales['Etude'] += 1
         prestations_normales['JoursEtude'] += "#{jour}, "
      end
      return prestations_normales
   end

   def Facturation.calc_majoration(prestations_majorees, prestation, tarif, tarif_majore, jour)

      # Repas
      if prestation.repas == '3'
        prestations_majorees['Repas'] += 1
        prestations_majorees['JoursRepas'] += "#{jour}, "

        if prestations_majorees['Repas'] > 2
           prestations_majorees['MntRepas'] += tarif_majore.RepasP
           prestations_majorees['PrixRepas'] = tarif_majore.RepasP
        else
           prestations_majorees['MntRepas'] += tarif.RepasP
           prestations_majorees['PrixRepas'] += tarif.RepasP
        end
      end

      #Garderie
      if prestation.garderieAM == '3'
         prestations_majorees['PrixGarderieAM'] = tarif_majore.GarderieAMP
         prestations_majorees['MntGarderieAM'] += tarif_majore.GarderieAMP
         prestations_majorees['GarderieAM'] += 1
         prestations_majorees['JoursGarderieAM'] += "#{jour}, "
      end
      if prestation.garderiePM == '3'
         prestations_majorees['PrixGarderiePM'] = tarif_majore.GarderiePMP
         prestations_majorees['MntGarderiePM'] += tarif_majore.GarderiePMP
         prestations_majorees['GarderiePM'] += 1
         prestations_majorees['JoursGarderiePM'] += "#{jour}, "
      end

      #Centre
      if prestation.centreAM == '3' and prestation.centrePM == '3'
         prestations_majorees['PrixCentreAMPM'] = tarif_majore.CentreAMPMP
         prestations_majorees['MntCentreAMPM'] += tarif_majore.CentreAMPMP
         prestations_majorees['CentreAMPM'] += 1
         prestations_majorees['JoursCentreAMPM'] += "#{jour}, "
      else
        if prestation.centreAM == '3'
           prestations_majorees['PrixCentreAM'] = tarif_majore.CentreAMP
           prestations_majorees['MntCentreAM'] += tarif_majore.CentreAMP
           prestations_majorees['CentreAM'] += 1
           prestations_majorees['JoursCentreAM'] += "#{jour}, "
        end
        if prestation.centrePM == '3'
           prestations_majorees['PrixCentrePM'] = tarif_majore.CentrePMP
           prestations_majorees['MntCentrePM'] += tarif_majore.CentrePMP
           prestations_majorees['CentrePM'] += 1
           prestations_majorees['JoursCentrePM'] += "#{jour}, "
        end
      end

      # Etude
      if prestation.etude == '3'
         prestations_majorees['PrixEtude'] = tarif.Etude
         prestations_majorees['MntEtude'] += tarif.Etude
         prestations_majorees['Etude'] += 1
         prestations_majorees['JoursEtude'] += "#{jour}, "
      end

      return prestations_majorees
   end

   def Facturation.calc_annulation(prestations_annulees, prestation, tarif, jour)

      # Repas
      if prestation.repas == '2'
        prestations_annulees['PrixRepas'] = tarif.RepasP
        prestations_annulees['MntRepas'] -= tarif.RepasP
        prestations_annulees['Repas'] += 1
        prestations_annulees['JoursRepas'] += "#{jour}, "
      end

      #Garderie
      if prestation.garderieAM == '2'
         prestations_annulees['PrixGarderieAM'] = tarif.GarderieAMP
         prestations_annulees['MntGarderieAM'] -= tarif.GarderieAMP
         prestations_annulees['GarderieAM'] += 1
         prestations_annulees['JoursGarderieAM'] += "#{jour}, "
      end
      if prestation.garderiePM == '2'
         prestations_annulees['PrixGarderiePM'] = tarif.GarderiePMP
         prestations_annulees['MntGarderiePM'] -= tarif.GarderiePMP
         prestations_annulees['GarderiePM'] += 1
         prestations_annulees['JoursGarderiePM'] += "#{jour}, "
      end

      #Centre
      if prestation.centreAM == '2' and prestation.centrePM == '2'
         prestations_annulees['PrixCentreAMPM'] = tarif.CentreAMPMP
         prestations_annulees['MntCentreAMPM'] -= tarif.CentreAMPMP
         prestations_annulees['CentreAMPM'] += 1
         prestations_annulees['JoursCentreAMPM'] += "#{jour}, "
      else
        if prestation.centreAM == '2'
           prestations_annulees['PrixCentreAM'] = tarif.CentreAMP
           prestations_annulees['MntCentreAM'] -= tarif.CentreAMP
           prestations_annulees['CentreAM'] += 1
           prestations_annulees['JoursCentreAM'] += "#{jour}, "
        end
        if prestation.centrePM == '2'
           prestations_annulees['PrixCentrePM'] = tarif.CentrePMP
           prestations_annulees['MntCentrePM'] -= tarif.CentrePMP
           prestations_annulees['CentrePM'] += 1
           prestations_annulees['JoursCentrePM'] += "#{jour}, "
        end
      end

      # Etude
      if prestation.etude == '2'
         prestations_annulees['PrixEtude'] = tarif.Etude
         prestations_annulees['MntEtude'] -= tarif.Etude
         prestations_annulees['Etude'] += 1
         prestations_annulees['JoursEtude'] += "#{jour}, "
      end

      return prestations_annulees
   end

   def Facturation.calc_annulation_maladie(prestations_annulees_maladie, prestation, tarif, jour)
  
      # Repas
      if prestation.repas == '4'
         prestations_annulees_maladie['Repas'] += 1
         prestations_annulees_maladie['JoursRepas'] += "#{jour}, "
         # TODO : jour de carence dans le tarif
         if prestations_annulees_maladie['Repas'] > 1
            prestations_annulees_maladie['MntRepas'] -= tarif.RepasP
         end
         prestations_annulees_maladie['PrixRepas'] = tarif.RepasP
      end

      #Garderie
      if prestation.garderieAM == '4'
         prestations_annulees_maladie['MntGarderieAM'] -= tarif.GarderieAMP
         prestations_annulees_maladie['PrixGarderieAM'] = tarif.GarderieAMP
         prestations_annulees_maladie['GarderieAM'] += 1
         prestations_annulees_maladie['JoursGarderieAM'] += "#{jour}, "
      end
      if prestation.garderiePM == '4'
         prestations_annulees_maladie['PrixGarderiePM'] = tarif.GarderiePMP
         prestations_annulees_maladie['MntGarderiePM'] -= tarif.GarderiePMP
         prestations_annulees_maladie['GarderiePM'] += 1
         prestations_annulees_maladie['JoursGarderiePM'] += "#{jour}, "
      end

      #Centre
      if prestation.centreAM == '4' and prestation.centrePM == '4'
         prestations_annulees_maladie['PrixCentreAMPM'] = tarif.CentreAMPMP
         prestations_annulees_maladie['MntCentreAMPM'] -= tarif.CentreAMPMP
         prestations_annulees_maladie['CentreAMPM'] += 1
         prestations_annulees_maladie['JoursCentreAMPM'] += "#{jour}, "
      else
        if prestation.centreAM == '4'
           prestations_annulees_maladie['PrixCentreAM'] = tarif.CentreAMP
           prestations_annulees_maladie['MntCentreAM'] -= tarif.CentreAMP
           prestations_annulees_maladie['CentreAM'] += 1
           prestations_annulees_maladie['JoursCentreAM'] += "#{jour}, "
        end
        if prestation.centrePM == '4'
           prestations_annulees_maladie['PrixCentrePM'] = tarif.CentrePMP
           prestations_annulees_maladie['MntCentrePM'] -= tarif.CentrePMP
           prestations_annulees_maladie['CentrePM'] += 1
           prestations_annulees_maladie['JoursCentrePM'] += "#{jour}, "
        end
      end

      # Etude
      if prestation.etude == '4'
        prestations_annulees_maladie['PrixEtude'] = tarif.Etude
        prestations_annulees_maladie['MntEtude'] -= tarif.Etude
        prestations_annulees_maladie['Etude'] += 1
        prestations_annulees_maladie['JoursEtude'] += "#{jour}, "
      end

      return prestations_annulees_maladie
   end

end
