# encoding: utf-8

class UploadController < ApplicationController

  require 'parsedate'

  layout 'standard'

  def index
  end

  def uploadFile

    if params[:upload]['datafile'].empty?
	flash[:warning] = 'Aucun fichier à importer...'
	redirect_to :action => 'index'
    else

	    #save file 
	    post = DataFile.save(params[:upload], session[:mairie])
	    # load saved file
	    name =  params[:upload]['datafile'].original_filename
	    directory = ["public/data/",session[:mairie].to_s]
	    # create the file path
	    path = File.join(directory, name)

	    #open file
	    f = File.new(path)


	    f.each { |line|
	       #split line
	       message = line.split(";")
	       log_id = message[0]
	       log_enfant_id= message[1]
	       log_date = message[2]
	       logger.info(line)
	      
	       #transforme chaine date en datetime  --- Attention jour  = mois
	       d = ParseDate.parsedate(log_date)
	       time = Time.local(*d)
	       log_date = time.strftime("%Y-%d-%m")

	       prestaAM = nil
	       prestaPM = nil
	       prestaRepas = nil
	
	       
	       case time.hour
		  when 0..9 #mettre heure de garderie Matin en variable mairie
		    minutes = (time.hour * 60) + time.min
		    diff = (9*60) - minutes
		    case diff
		       when 0..60
			  prestaAM = 5
			  logger.info("une heure de garderie Matin")
		       when 60..90
			  prestaAM = 6
		          logger.info("une heure et demi de garderie Matin")
		       when 90..120
			  prestaAM = 7
		          logger.info("deux heures de garderie Matin")
		    end 

		  when 12..14 
		    prestaRepas = 1	
		    logger.info("Repas")


		  when 16..23 #mettre heure de garderie Soir en variable mairie
		    minutes = (time.hour * 60) + time.min
		    diff = minutes - (16*60)
		    case diff
		       when 0..60
			  prestaPM = 5
		          logger.info("une heure de garderie soir")
		       when 60..90
			  prestaPM = 6
		          logger.info("une heure et demi de garderie Soir")
		       when 90..120
			  prestaPM = 7
		          logger.info("deux heures de garderie Soir")
		    end 
	       end

	       if (prestaAM or prestaPM or prestaRepas)
		       p = Prestation.find(:first, :conditions => ['enfant_id= ? AND date = ?', log_enfant_id, log_date])	
		       unless p
			  p = Prestation.new
			  p.enfant_id = log_enfant_id
			  p.date = log_date
		       end
		       p.garderieAM = prestaAM if prestaAM
		       p.garderiePM = prestaPM if prestaPM
		       p.repas = 1 if prestaRepas
		       if p.save
			   logger.info("OK")
		       else
			   logger.info("ERREUR")
		       end
	       end 	  

	    }
	    render :text => "Fichier importé"
	end
  end

end
