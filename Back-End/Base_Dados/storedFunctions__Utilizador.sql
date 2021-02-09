
-- ------------------------------------------------------
-- ------------------------------------------------------
-- Universidade do Minho
-- Mestrado Integrado em Engenharia Informática (MiEI)
-- Unidade Curricular de Laboratórios de Informática IV (LI4)
-- 
-- Caso de Estudo: IQueue
-- Criação de Stored Procedures, Triggers, Events, Views e Functions
--
-- Março/2020
-- Grupo 2, Turno 2
-- ------------------------------------------------------
-- ------------------------------------------------------

/* 

								***************************** INFO *****************************

	As seguintes procedures/views/functions têm em conta quem as invocou, utilizando a propria conexão-login para a identificação (sessão), 
	verificando a permissão para a sua execução e, portanto, 
    não dando hipótese de um qualquer utilizador poder obter informações ou realizar operações que não nada têm a ver consigo.
    De realçar também que essa conexão é via SLL e utilizando uma codificação hash 256 para a respectiva password.
    Logo, dando muita relevância à segurança, protecção, privacidade e performance.
    
    A password de acesso (connection to mysql db) é guardado num ficheiro criado pela db, logo inacessivel
    Visto que a password tb será guardado na tabela do Utilizador/Funcionario/Gerente mas não será utilizado
    (será utilizado a pass de conta criada na conexao para db, + eficiente e + seguro), para manter a coerência
    com o modelo será guardada mas encriptada (manter-se-ão ambas sincronizadas). 
    Dá para ter acesso à password guardada nessas tabelas (but why?) tendo que fazer AES_DECRYPT para tal
    com a string "UMinho2020Grupo2"
    
*/
		USE iqueue;
		SET @ESTADO_1 = 'Em Espera';
		SET @ESTADO_2 = 'Usado';
		SET @ESTADO_3 = 'Descartado';
		SET @ESTADO_4 = 'Inutilizado';

		DELIMITER $$


/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» UTILIZADOR »» Dados
****************************************************************************************************************************
****************************************************************************************************************************	
 */	
			DROP FUNCTION IF EXISTS `utilizador_reputacao` $$
			CREATE FUNCTION utilizador_reputacao() 
			RETURNS FLOAT(4)
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
						» protege os dados/servidor se a máquina-cliente for atacada
                
					Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
						Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                    
                    Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
						Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
				DECLARE reputacao FLOAT(4);
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;

				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;

				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;				

				SELECT MAX(id) INTO utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
				SELECT reputacao INTO reputacao FROM Utilizador WHERE id = utilizador_id;
				RETURN (reputacao);

			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`utilizador_reputacao` TO 'utilizador';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
            DROP FUNCTION IF EXISTS `utilizador_id` $$
            CREATE FUNCTION utilizador_id() 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE reputacao FLOAT(4);
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;

				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;

				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;				

				SELECT MAX(id) INTO utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

				RETURN (utilizador_id);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`utilizador_id` TO 'utilizador';
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
            DROP FUNCTION IF EXISTS `utilizador_ticket_a_frente` $$
            CREATE FUNCTION utilizador_ticket_a_frente(ticketid INT) 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE reputacao FLOAT(4);
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;
				DECLARE _servico_id INT;
				DECLARE _nr_acesso INT;
				DECLARE res INT;

				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;

				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;

				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;				

				IF(SELECT T.utilizador_id != _utilizador_id FROM Ticket AS T WHERE id = ticket_id) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GULAG! Ticket nao ser teu blyat!';
				END IF;
				IF(SELECT T.estado != @ESTADO_1 FROM Ticket AS T WHERE id = ticket_id) 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket em estar nao fila espera, blyat';
				END IF;

				SELECT id INTO _servico_id FROM Ticket WHERE id = ticketid;
				SELECT nr_acessso INTO _nr_acesso FROM Ticket WHERE id = ticketid;
				
				SELECT COALESCE(-(MIN(nr_acesso)-nr_acessso), 0) INTO res FROM Ticket T 
					WHERE 
						servico_id = _servico_id AND
						DATE(T.data) = DATE(NOW()) AND
						estado = @ESTADO_1;

				RETURN (res);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`ticket_a_frente` TO 'utilizador';
            -- FLUSH PRIVILEGES;