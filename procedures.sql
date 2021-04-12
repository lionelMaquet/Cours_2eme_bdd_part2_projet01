-- PROCEDURE 1 : Créer commande

DELIMITER |
CREATE PROCEDURE creer_commande(IN pi_email_client VARCHAR(200), IN pi_moyen_paiement VARCHAR(30))
BEGIN
	INSERT INTO commande VALUES (NULL, pi_email_client, current_timestamp(), "En cours", pi_moyen_paiement);
END |
DELIMITER ;

CALL creer_commande("albert_deux@gmail.com", "Paypal");

-- PROCEDURE 2 : Ajouter article à commande 

DELIMITER |
CREATE PROCEDURE ajouter_article_commande(IN pi_numero_commande INT, IN pi_numero_article INT, IN pi_quantite INT)
BEGIN
	INSERT INTO detail VALUES (pi_numero_commande, pi_numero_article, pi_quantite); 
END |
DELIMITER ; 

CALL ajouter_article_commande(1, 2, 3);
CALL ajouter_article_commande(1, 1, 4);

-- PROCEDURE 3 : Valider commande 
DROP PROCEDURE valider_commande;

DELIMITER |
CREATE PROCEDURE valider_commande (IN pi_numero_commande INT)
BEGIN
	-- variables, conditions, curseurs, gestionnaires
	DECLARE prix_total DECIMAL(9,2) DEFAULT 0.00;
    
    DECLARE current_num_article INT DEFAULT 0;
    DECLARE current_quantite INT DEFAULT 0;
    DECLARE current_prix DECIMAL(9,2) DEFAULT 0.00;
    
    DECLARE l_fin_de_boucle BOOLEAN DEFAULT FALSE;
    
    -- curseurs
    DECLARE curseur_prix CURSOR 
    FOR 
		SELECT article_numero, quantite FROM detail 
        WHERE commande_numero = pi_numero_commande;
        
	-- gestionnaire
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_fin_de_boucle := TRUE;
		
        
	OPEN curseur_prix; 
    REPEAT
		FETCH curseur_prix INTO current_num_article, current_quantite;
        SELECT prix * current_quantite INTO current_prix FROM article WHERE numero = current_num_article;
        IF l_fin_de_boucle = FALSE
			THEN
			SET prix_total := prix_total + current_prix;
		END IF;
	UNTIL l_fin_de_boucle = TRUE
    END REPEAT;
    CLOSE curseur_prix;
    
    INSERT INTO paiement VALUES (pi_numero_commande, current_timestamp(), prix_total , "Ouvert");

	UPDATE commande
	SET statut = "Validée" 
    WHERE numero = pi_numero_commande;
END |
DELIMITER ;

CALL valider_commande (1);



-- PROCEDURE 4 : Payer commande 

DELIMITER | 
CREATE PROCEDURE payer_commande (IN pi_commande_num INT, IN pi_montant DECIMAL(9,2))
BEGIN
	DECLARE old_prix DECIMAL(9,2);
    SELECT solde INTO old_prix
    FROM paiement WHERE commande_numero = pi_commande_num;
    
    IF old_prix >= pi_montant
    THEN
		UPDATE paiement
        SET solde = old_prix - pi_montant
        WHERE commande_numero = pi_commande_num;
	END IF;
	-- Le changement de statut est provoqué par un trigger 
END |
DELIMITER ;

CALL payer_commande(1, 0);

-- PROCEDURE 5 : Commande livrée

DELIMITER |
CREATE PROCEDURE commande_livree (IN pi_commande_num INT)
BEGIN
	UPDATE commande
    SET statut = "Livrée"
    WHERE numero = pi_commande_num;
END |
DELIMITER ;

CALL commande_livree(1);







