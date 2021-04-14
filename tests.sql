-- 1 : On crée une commande à l'aide d'une procédure
CALL creer_commande("albert_deux@gmail.com", "Paypal");

-- Pour la suite, nous aurons besoin de l'identifiant de la commande créée. Créons donc une variable utilisateur pour la réutiliser.
-- A noter qu'un email ne peut être associé qu'à une seule commande en cours à la fois (voir procedure creer_commande)
SELECT numero INTO @num_cmd FROM commande WHERE client_email = "albert_deux@gmail.com" AND statut = "En cours" ;

-- 2 : On ajoute des articles à la commande créée
CALL ajouter_article_commande(@num_cmd, 3, 1);
CALL ajouter_article_commande(@num_cmd, 2, 2);

-- 3 : Une fois que tous les articles souhaités sont ajoutés à la commande, on la valide 
CALL valider_commande (@num_cmd);

-- 4 : Une fois que la commande est validée, nous utilisons la fonction "payer" pour régler le solde.
-- Cette fonction permet également, pour plus de flexibilité, de régler une PARTIE du solde restant. 
-- Bien sûr, la commande ne sera considérée payée que quand le solde sera complètement clotûré.
CALL payer_commande(@num_cmd, 5.97);
CALL payer_commande(@num_cmd, 4);

-- 5 : Indiquer que la commande a été livrée
-- Une fois que le paiement est entièrement réglé, la commande passe automatiquement en mode "En livraison".
-- Cette étape sert donc à cloturer véritablement l'état de la commande dans le système et d'indiquer qu'elle a été livrée.
CALL commande_livree(@num_cmd);

-- ------------------------------- --
-- --- PROCEDURES STATISTIQUES --- --
-- ------------------------------- -- 

-- Pour connaître le montant total en attente de paiement
CALL montant_total_attente_paiement();

-- Pour connaître le délai moyen entre la création d'une commande et la clotûre d'un paiement
CALL delai_moyen();

-- Pour connaître l'article le plus vendu 
CALL article_populaire();
