DROP TRIGGER IF EXISTS paiement_before_update;
DELIMITER |
CREATE TRIGGER paiement_before_update
BEFORE UPDATE
ON paiement
FOR EACH ROW 
BEGIN
	IF NEW.solde = 0.00
    THEN 
		SET NEW.statut := "Cloturé";
        UPDATE commande 
        SET statut = "En préparation"
        WHERE numero = NEW.commande_numero;
	END IF;
END |
DELIMITER ;