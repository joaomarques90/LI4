
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
    com a string 'UMinho2020Grupo2'
    
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
												PROCEDURES »»»»»»»»» EVENTS
****************************************************************************************************************************
****************************************************************************************************************************
*/

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» EVENTS »»»» UPDATES (ESTATISTICAS)
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- SE EXISTIR ENTAO ACTUALIZAR; SE NAO EXISTIR => INSERT VAZIO
			DROP PROCEDURE IF EXISTS `update_estatistica_real` $$
			CREATE PROCEDURE `update_estatistica_real`()
			BEGIN
				DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;

				-- DECLARE contador INT DEFAULT 0;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				CREATE TEMPORARY TABLE tabela_temp engine=memory 
					SELECT 
						T.id AS ticketID, T.estado AS ticketEstado, T.data AS ticketData, 
                        T.tempo_espera AS ticketTempoEspera, T.tempo_atendimento AS ticketTempoAtendimento,
							S.id AS servicoID, -- S.estado AS servicoEstado,
							SUBTIME(TIMESTAMP(DATE(NOW()), S.hora_abertura),'0 00:10:00') AS ServicoAbertura, -- 10 MINUTE SOONER
							ADDTIME(TIMESTAMP(DATE(NOW()), S.hora_fecho),'0 01:30:00') AS ServicoFecho -- 90 MINUTE LATER
							-- ,E.tempo_espera AS tempo_espera_RealHoraria, E.tempo_atendimento AS tempo_atendimento_RealHoraria
								FROM Estatistica_Tempo_Real E 
									JOIN Servico S 
										ON S.id = E.servico_id
											JOIN Ticket T 
												ON S.id = T.servico_id 
												WHERE (T.estado = 'Em Espera' OR T.estado = 'Usado') AND 
													  T.data >= DATE_SUB(NOW(), INTERVAL 90 MINUTE)
												ORDER BY servicoID, ticketData;
					
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;
				CREATE TEMPORARY TABLE tabela_temp_services engine=memory 
						SELECT *
							FROM tabela_temp 
								GROUP BY servicoID 
									HAVING COUNT(servicoID) >= 1; 
				-- CONGESTAO
				UPDATE Estatistica_Tempo_Real E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.servicoID
					SET E.congestao = (
								SELECT COALESCE(Count(TTC.ticketID),0) FROM tabela_temp AS TTC
                                WHERE E.servico_id = TTC.servicoID AND 
                                      TTC.ticketEstado = 'Em Espera'
                                )
					WHERE ((NOW() <= TT.ServicoFecho AND NOW() >= TT.ServicoAbertura) OR
                          (SUBTIME(TT.ServicoFecho, '01:30:00') = ADDTIME(TT.ServicoAbertura, '00:10:00'))) AND
                          E.servico_id IS NOT NULL;
					
				-- TEMPO_ESPERA: EXISTENTE
				UPDATE Estatistica_Tempo_Real E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.servicoID
					SET tempo_espera = (
								SELECT COALESCE(SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.ticketTempoEspera))),'00:00:00') FROM tabela_temp AS TTC
								WHERE 
									E.servico_id = TTC.servicoID AND 
                                    (TTC.ticketEstado = 'Usado' OR TTC.ticketEstado = 'Em Espera') AND
                                    TTC.ticketTempoEspera IS NOT NULL
								)
					WHERE ((NOW() <= TT.ServicoFecho AND NOW() >= TT.ServicoAbertura) OR
                          (SUBTIME(TT.ServicoFecho, '01:30:00') = ADDTIME(TT.ServicoAbertura, '00:10:00'))) AND
                          E.servico_id IS NOT NULL;
						
				-- TEMPO_ATENDIMENTO: EXISTENTE
				UPDATE Estatistica_Tempo_Real E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.servicoID
					SET tempo_atendimento = (
								SELECT COALESCE(SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.ticketTempoAtendimento))),'00:00:00') FROM tabela_temp AS TTC
								WHERE 
									E.servico_id = TTC.servicoID AND 
                                    TTC.ticketEstado = 'Usado' AND
                                    TTC.ticketTempoAtendimento IS NOT NULL
								)
					WHERE ((NOW() <= TT.ServicoFecho AND NOW() >= TT.ServicoAbertura) OR
                          (SUBTIME(TT.ServicoFecho, '01:30:00') = ADDTIME(TT.ServicoAbertura, '00:10:00'))) AND
                          E.servico_id IS NOT NULL;
                    
				-- TEMPO_ESPERA: INEXISTENTE E SERVICO ESTA ACTIVO
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                CREATE TEMPORARY TABLE tabela_temp_2 engine=memory 
					SELECT S.id AS servicoID
						FROM Estatistica_Tempo_Real E RIGHT JOIN Servico S
							ON E.servico_id = S.id AND S.estado = TRUE
							WHERE E.servico_id IS NULL AND S.estado = TRUE;
                            
                -- SELECT COALESCE(COUNT(servicoID),0) INTO contador FROM tabela_temp_2;
                IF EXISTS(SELECT servicoID FROM tabela_temp_2) THEN
					BEGIN
						INSERT INTO Estatistica_Tempo_Real (servico_id, congestao, tempo_espera, tempo_atendimento) 
							SELECT servicoID, 0, '00:00:00', '00:00:00' FROM tabela_temp_2;
					END;
				END IF;
				/*			
				-- TEMPO_ESPERA: RESTART COUTING AT BEGINNING OF DAY IF SERVICO ACTIVO
					UPDATE Estatistica_Tempo_Real E JOIN tabela_temp
						SET tempo_medio_espera = '00:00:00' 
						WHERE 
							E.tempo_medio_espera IS NOT NULL AND
							E.servico_id = tabela_temp.id AND 
							tabela_temp.estado = TRUE AND
							tabela_temp.abertura >= TIME(now());
					
				*/			
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;

                COMMIT;
			END$$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- SE EXISTIR ENTAO ACTUALIZAR, SE NAO EXISTIR, INSERT VAZIO
			DROP PROCEDURE IF EXISTS `update_estatistica_diaria` $$
			CREATE PROCEDURE `update_estatistica_diaria`()
			BEGIN

				DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				CREATE TEMPORARY TABLE tabela_temp engine=memory 
					SELECT 
						T.id AS ticketID, T.estado AS ticketEstado, T.data AS ticketData, 
                        T.tempo_espera AS ticketTempoEspera, T.tempo_atendimento AS ticketTempoAtendimento,
							S.id AS servicoID, -- S.estado AS servicoEstado,
							SUBTIME(TIMESTAMP(DATE(NOW()), S.hora_abertura),'0 00:10:00') AS ServicoAbertura, -- 10 MINUTE SOONER
							ADDTIME(TIMESTAMP(DATE(NOW()), S.hora_fecho),'0 01:30:00') AS ServicoFecho -- 90 MINUTE LATER
							-- ,E.tempo_espera AS tempo_espera_RealHoraria, E.tempo_atendimento AS tempo_atendimento_RealHoraria
								FROM Estatistica_Diaria E 
									JOIN Servico S 
										ON S.id = E.servico_id
											JOIN Ticket T 
												ON S.id = T.servico_id 
												WHERE (T.estado = 'Em Espera' OR T.estado = 'Usado') AND 
													  DATE(E.data) = DATE(NOW()) AND
													  T.data >= SUBTIME(TIMESTAMP(DATE(NOW()), S.hora_abertura),'0 00:10:00')
												ORDER BY servicoID, ticketData;
						
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;
				CREATE TEMPORARY TABLE tabela_temp_services engine=memory 
						SELECT *
							FROM tabela_temp 
								GROUP BY servicoID 
									HAVING COUNT(servicoID) >= 1; 
                
				-- CONGESTAO
				UPDATE Estatistica_Diaria E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.servicoID
					SET E.congestao_media = (
								SELECT COALESCE(ROUND( (SUM(TTC.ticketID) + E.congestao_media)/(1 + HOUR(TIMEDIFF(TTC.ServicoAbertura, TIME(NOW()))) ) ),0) 
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.servicoID AND
									  TTC.ticketEstado = 'Em Espera'
                                )
					WHERE DATE(E.data) = DATE(NOW()) AND
						  ((NOW() <= TT.ServicoFecho AND NOW() >= TT.ServicoAbertura) OR
                          (SUBTIME(TT.ServicoFecho, '01:30:00') = ADDTIME(TT.ServicoAbertura, '00:10:00'))) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.servicoID;
                    
				-- TEMPO_ESPERA: EXISTENTE
				UPDATE Estatistica_Diaria  E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.servicoID
					SET tempo_medio_espera = 
						(SELECT COALESCE(SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.ticketTempoEspera))),'00:00:00') 
							FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.servicoID AND
									  TTC.ticketTempoEspera IS NOT NULL AND
									  (TTC.ticketEstado = 'Usado' OR TTC.ticketEstado = 'Em Espera')
						)
					WHERE DATE(E.data) = DATE(NOW()) AND
						  ((NOW() <= TT.ServicoFecho AND NOW() >= TT.ServicoAbertura) OR
                          (SUBTIME(TT.ServicoFecho, '01:30:00') = ADDTIME(TT.ServicoAbertura, '00:10:00'))) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.servicoID;
				
                -- TEMPO_ATENDIMENTO: EXISTENTE
				UPDATE Estatistica_Diaria E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.servicoID
					SET tempo_atendimento = 
						(SELECT COALESCE(SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.ticketTempoAtendimento))),'00:00:00') 
                                FROM tabela_temp AS TTC
								WHERE 
									E.servico_id = TTC.servicoID AND 
                                    TTC.ticketEstado = 'Usado' AND
                                    TTC.ticketTempoAtendimento IS NOT NULL
						)
					WHERE DATE(E.data) = DATE(NOW()) AND
						  ((NOW() <= TT.ServicoFecho AND NOW() >= TT.ServicoAbertura) OR
                          (SUBTIME(TT.ServicoFecho, '01:30:00') = ADDTIME(TT.ServicoAbertura, '00:10:00'))) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.servicoID;
                    
                    
				-- TEMPO_ESPERA: INEXISTENTE E SERVICO ESTA ACTIVO
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                CREATE TEMPORARY TABLE tabela_temp_2 engine=memory 
					SELECT S.id AS servicoID
						FROM Estatistica_Diaria E RIGHT JOIN Servico S
							ON E.servico_id = S.id AND DATE(E.data) = DATE(NOW()) AND S.estado = TRUE
							WHERE E.servico_id IS NULL AND E.data IS NULL AND S.estado = TRUE;
                
                IF EXISTS(SELECT * FROM tabela_temp_2) 
					THEN
                        BEGIN
							INSERT INTO Estatistica_Diaria (data, servico_id, congestao_media, tempo_medio_espera, tempo_atendimento) 
								SELECT DATE(NOW()), servicoID, 0, '00:00:00', '00:00:00' FROM tabela_temp_2;
						END;
				END IF;
				
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;

                COMMIT;
			END$$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/			
			DROP PROCEDURE IF EXISTS `update_estatistica_semanal` $$
			CREATE PROCEDURE `update_estatistica_semanal`()
			BEGIN
				DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				CREATE TEMPORARY TABLE tabela_temp engine=memory 
					SELECT data AS diariaData, servico_id AS diariaServicoID, tempo_medio_espera AS diariaTempoEspera,
                           congestao_media AS diariaCongestao, tempo_atendimento AS diariaTempoAtendimento
								FROM Estatistica_Diaria E
									WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 WEEK))
												ORDER BY diariaServicoID, diariaData;
						
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;
				CREATE TEMPORARY TABLE tabela_temp_services engine=memory 
						SELECT diariaServicoID AS semanaServicoID, Count(diariaServicoID) AS qtd_Semana
							FROM tabela_temp 
								GROUP BY diariaServicoID ; 
                
				-- CONGESTAO
				UPDATE Estatistica_Semanal E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.semanaServicoID
					SET E.congestao_media = (
								SELECT ROUND(AVG(TTC.diariaCongestao))
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.diariaServicoID AND
									  TT.semanaServicoID = TTC.diariaServicoID
                                )
					WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 WEEK)) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.semanaServicoID;
                    
				-- TEMPO_ESPERA: EXISTENTE
				UPDATE Estatistica_Semanal E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.semanaServicoID
					SET E.tempo_medio_espera = (
								SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.diariaTempoEspera)))
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.diariaServicoID AND
									  TT.semanaServicoID = TTC.diariaServicoID
                                )
					WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 WEEK)) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.semanaServicoID;
				
                -- TEMPO_ATENDIMENTO: EXISTENTE
				UPDATE Estatistica_Semanal E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.semanaServicoID
					SET E.tempo_atendimento = (
								SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.diariaTempoAtendimento)))
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.diariaServicoID AND
									  TT.semanaServicoID = TTC.diariaServicoID
                                )
					WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 WEEK)) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.semanaServicoID;
                    
                    
				-- TEMPO_ESPERA: INEXISTENTE E SERVICO ESTA ACTIVO
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                CREATE TEMPORARY TABLE tabela_temp_2 engine=memory 
					SELECT S.id AS servicoID
						FROM Estatistica_Semanal E RIGHT JOIN Servico S
							ON E.servico_id = S.id AND DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 WEEK)) AND S.estado = TRUE
							WHERE E.servico_id IS NULL AND E.data IS NULL AND S.estado = TRUE;
                
                IF EXISTS(SELECT * FROM tabela_temp_2) 
					THEN
                        BEGIN
							INSERT INTO Estatistica_Semanal (data, servico_id, congestao_media, tempo_medio_espera, tempo_atendimento) 
								SELECT DATE(DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 WEEK), INTERVAL 1 DAY)), servicoID, 0, '00:00:00', '00:00:00' FROM tabela_temp_2;
						END;
				END IF;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                CREATE TEMPORARY TABLE tabela_temp_2 engine=memory 
					SELECT S.id AS servicoID
						FROM Estatistica_Semanal E RIGHT JOIN Servico S
							ON E.servico_id = S.id AND DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 WEEK)) AND S.estado = FALSE
							WHERE E.servico_id IS NULL AND E.data IS NULL AND S.estado = FALSE;
                            
                            
				IF EXISTS(SELECT * FROM tabela_temp_2) 
					THEN
                        BEGIN
							INSERT INTO Estatistica_Semanal (data, servico_id, congestao_media, tempo_medio_espera, tempo_atendimento) 
								SELECT DATE(DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 WEEK), INTERVAL 1 DAY)), servicoID, NULL, NULL, NULL FROM tabela_temp_2;
						END;
				END IF;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;

                COMMIT;
			END$$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- SE EXISTIR ENTAO ACTUALIZAR, SE NAO EXISTIR, INSERT VAZIO
			DROP PROCEDURE IF EXISTS `update_estatistica_mensal` $$
			CREATE PROCEDURE `update_estatistica_mensal`()
			BEGIN

				DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;

				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				CREATE TEMPORARY TABLE tabela_temp engine=memory 
					SELECT data AS diariaData, servico_id AS diariaServicoID, tempo_medio_espera AS diariaTempoEspera,
                           congestao_media AS diariaCongestao, tempo_atendimento AS diariaTempoAtendimento
								FROM Estatistica_Diaria E
									WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 MONTH))
												ORDER BY diariaServicoID, diariaData;
						
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;
				CREATE TEMPORARY TABLE tabela_temp_services engine=memory 
						SELECT diariaServicoID AS mesServicoID, Count(diariaServicoID) AS qtd_Semana
							FROM tabela_temp 
								GROUP BY diariaServicoID ; 
                
				-- CONGESTAO
				UPDATE Estatistica_Mensal E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.mesServicoID
					SET E.congestao_media = (
								SELECT ROUND(AVG(TTC.diariaCongestao))
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.diariaServicoID AND
									  TT.mesServicoID = TTC.diariaServicoID
                                )
					WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 MONTH)) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.mesServicoID;
                    
				-- TEMPO_ESPERA: EXISTENTE
				UPDATE Estatistica_Mensal E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.mesServicoID
					SET E.tempo_medio_espera = (
								SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.diariaTempoEspera)))
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.diariaServicoID AND
									  TT.mesServicoID = TTC.diariaServicoID
                                )
					WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 MONTH)) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.mesServicoID;
				
                -- TEMPO_ATENDIMENTO: EXISTENTE
				UPDATE Estatistica_Mensal E INNER JOIN tabela_temp_services TT ON E.servico_id = TT.mesServicoID
					SET E.tempo_atendimento = (
								SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(TTC.diariaTempoAtendimento)))
                                FROM tabela_temp TTC
                                WHERE E.servico_id = TTC.diariaServicoID AND
									  TT.mesServicoID = TTC.diariaServicoID
                                )
					WHERE DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 MONTH)) AND
                          E.servico_id IS NOT NULL AND
                          E.servico_id = TT.mesServicoID;
                    
                    
				-- TEMPO_ESPERA: INEXISTENTE E SERVICO ESTA ACTIVO
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                CREATE TEMPORARY TABLE tabela_temp_2 engine=memory 
					SELECT S.id AS servicoID
						FROM Estatistica_Mensal E RIGHT JOIN Servico S
							ON E.servico_id = S.id AND DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 MONTH)) AND S.estado = TRUE
							WHERE E.servico_id IS NULL AND E.data IS NULL AND S.estado = TRUE;
                
                IF EXISTS(SELECT * FROM tabela_temp_2) 
					THEN
                        BEGIN
							INSERT INTO Estatistica_Mensal (data, servico_id, congestao_media, tempo_medio_espera, tempo_atendimento) 
								SELECT DATE(DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 MONTH), INTERVAL 1 DAY)), servicoID, 0, '00:00:00', '00:00:00' FROM tabela_temp_2;
						END;
				END IF;
                
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                CREATE TEMPORARY TABLE tabela_temp_2 engine=memory 
					SELECT S.id AS servicoID
						FROM Estatistica_Mensal E RIGHT JOIN Servico S
							ON E.servico_id = S.id AND DATE(E.data) > DATE(DATE_SUB(NOW(), INTERVAL 1 MONTH)) AND S.estado = FALSE
							WHERE E.servico_id IS NULL AND E.data IS NULL AND S.estado = FALSE;
                
                IF EXISTS(SELECT * FROM tabela_temp_2) 
					THEN
                        BEGIN 
							INSERT INTO Estatistica_Mensal (data, servico_id, congestao_media, tempo_medio_espera, tempo_atendimento) 
								SELECT DATE(DATE_ADD(DATE_SUB(NOW(), INTERVAL 1 MONTH), INTERVAL 1 DAY)), servicoID, NULL, NULL, NULL FROM tabela_temp_2;
						END;
				END IF;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_2;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_services;

                COMMIT;
			END$$

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» EVENTS »»»» INIT/SCHEDULE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	/*

				DELIMITER $$
				DROP EVENT IF EXISTS `myeventnotUsedTicketTolerance` $$
				CREATE EVENT myeventnotUsedTicketTolerance
					ON SCHEDULE EVERY 20 second
                    STARTS (TIMESTAMP(CURRENT_DATE))
                    ON COMPLETION PRESERVE
					-- STARTS '07:00:00'
					-- ENDS '23:00:00'
					DO 
						proc_label:BEGIN
							IF curtime() >= '23:00' OR curtime() <= '07:00' THEN
								LEAVE proc_label;
							END IF;
        
						UPDATE Ticket AS Ti SET estado = 'Inutilizado'
								WHERE
									(
										Ti.estado = 'Em Espera' AND 
										Ti.tempo_medio_espera = NULL AND
										DATE(Ti.data) = DATE(NOW()) AND
										// 5 minutos de tolerancia para uso 
										timediff(NOW(),Ti.data) > TIME('00:05:00')
									);
						END
				$$
	*/


/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
                DELIMITER $$
                DROP EVENT IF EXISTS `myeventDescartaTickets` $$
                CREATE EVENT myeventDescartaTickets
                    ON SCHEDULE EVERY 1 HOUR
                    STARTS (TIMESTAMP(CURRENT_DATE))
                    ON COMPLETION PRESERVE
                    DO
                      BEGIN
                        
							UPDATE Ticket  SET 
												estado = 'Descartado',
												observacoes = IFNULL(CONCAT( observacoes , CONCAT("\nTicket descartado por inactividade em ", NOW()) ), CONCAT("Ticket descartado por inactividade em ", NOW()))
												WHERE
													estado = 'Em Espera' AND
													data <= DATE_SUB(NOW(), INTERVAL 36 HOUR) AND
													tempo_espera IS NULL;

                      END
                $$




 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
        
				DELIMITER $$
				DROP EVENT IF EXISTS `myeventEstatisticaRealHoraria` $$
				CREATE EVENT myeventEstatisticaRealHoraria
					ON SCHEDULE EVERY 3 MINUTE
					STARTS (TIMESTAMP(CURRENT_DATE))
					ON COMPLETION PRESERVE
					-- STARTS MIN(openTime)
					-- ENDS MAX(closeTime)
                    
					DO 
						proc_label:BEGIN
                        
							DECLARE closeTime TIME;
							DECLARE closeTime_aux TIME;
							DECLARE openTime TIME;
							
							SELECT MAX(hora_fecho) INTO closeTime FROM Servico;
							SELECT MIN(hora_abertura) INTO openTime FROM Servico;
                            SELECT MIN(hora_fecho) INTO closeTime_aux FROM Servico;
							
							IF(closeTime_aux >= openTime) THEN SET closeTime = openTime = '00:00:00'; END IF;
                            
                            IF(openTime != closeTime) THEN 
										IF openTime >= '00:10:00' 
											THEN SET openTime = SUBTIME(openTime, '00:10:00');
											ELSE SET openTime = '00:00:00';
                                        END IF;
                                        IF closeTime >= '22:30:00' 
											THEN SET closeTime = '00:00:00'; -- ADDTIME('00:00:00',(SUBTIME('01:30:00',SUBTIME('24:00:00', closeTime))));
											ELSE SET closeTime = ADDTIME(closeTime,'01:30:00');
                                        END IF;
							END IF;
							
							IF openTime != closeTime THEN
								IF curtime() > closeTime OR CURTIME() < openTime THEN
									LEAVE proc_label;
								END IF;
							END IF;
								
							CALL update_estatistica_real();
                       
						END
				$$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				DELIMITER $$
				DROP EVENT IF EXISTS `myeventEstatisticaDiaria` $$
				CREATE EVENT myeventEstatisticaDiaria
					ON SCHEDULE EVERY 1 HOUR
                    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL - 1 MINUTE)
                    ON COMPLETION PRESERVE
					-- STARTS MIN(openTime)
					-- ENDS MAX(closeTime)
					DO 
						proc_label:BEGIN
                        
							DECLARE closeTime TIME;
							DECLARE closeTime_aux TIME;
							DECLARE openTime TIME;
							
							SELECT MAX(hora_fecho) INTO closeTime FROM Servico;
							SELECT MIN(hora_abertura) INTO openTime FROM Servico;
                            SELECT MIN(hora_fecho) INTO closeTime_aux FROM Servico;
							
							IF(closeTime_aux >= openTime) THEN SET closeTime = openTime = '00:00:00'; END IF;
                            
                            IF(openTime != closeTime) THEN 
										IF openTime >= '00:10:00' 
											THEN SET openTime = SUBTIME(openTime, '00:10:00');
											ELSE SET openTime = '00:00:00';
                                        END IF;
                                        IF closeTime >= '22:30:00' 
											THEN SET closeTime = '00:00:00'; -- ADDTIME('00:00:00',(SUBTIME('01:30:00',SUBTIME('24:00:00', closeTime))));
											ELSE SET closeTime = ADDTIME(closeTime,'01:30:00');
                                        END IF;
							END IF;
							
							IF openTime != closeTime THEN
								IF curtime() > closeTime OR CURTIME() < openTime THEN
									LEAVE proc_label;
								END IF;
							END IF;
                            
							CALL update_estatistica_diaria();
					END
				$$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				DELIMITER $$
				DROP EVENT IF EXISTS `myeventEstatisticaSemanal` $$
				CREATE EVENT myeventEstatisticaSemanal
					ON SCHEDULE EVERY 24 HOUR 
                    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL - 1 MINUTE)
                    ON COMPLETION PRESERVE
					DO 
					   CALL update_estatistica_semanal();
				$$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				DELIMITER $$
				DROP EVENT IF EXISTS `myeventEstatisticaMensal` $$
				CREATE EVENT myeventEstatisticaMensal
					ON SCHEDULE EVERY 24 HOUR
					STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL - 1 MINUTE)
					ON COMPLETION PRESERVE
					DO
					  CALL update_estatistica_mensal();
				$$

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				DELIMITER $$
				DROP EVENT IF EXISTS `myeventTicketNumZero` $$
				CREATE EVENT myeventTicketNumZero
					ON SCHEDULE EVERY 24 HOUR
					STARTS (TIMESTAMP(CURRENT_DATE))
					ON COMPLETION PRESERVE
					DO
					  BEGIN
					  	DROP TEMPORARY TABLE IF EXISTS tabela_temp_3;
		                CREATE TEMPORARY TABLE tabela_temp_3 engine=memory 
							SELECT S.id AS servicoID, COALESCE(MIN(T.nr_acesso),0) AS nr_acessoT
								FROM Servico S INNER JOIN Ticket T 
									ON T.servico_id = S.id
									WHERE T.servico_id IS NOT NULL AND T.servico_id = S.id AND 
										  DATE(T.data) = CURDATE() AND T.estado = 'Em Espera'
                				GROUP BY servicoID;
					  	
                		UPDATE Servico S INNER JOIN tabela_temp_3 TT ON S.id = TT.servicoID
                			SET ticket_atual = nr_acessoT
                				WHERE S.id = TT.servicoID;
                                
						DROP TEMPORARY TABLE IF EXISTS tabela_temp_4;
                        CREATE TEMPORARY TABLE tabela_temp_4 engine=memory 
								SELECT * FROM Servico
								LEFT JOIN tabela_temp_3 ON Servico.id = tabela_temp_3.servicoID
								UNION ALL
								SELECT * FROM Servico
								RIGHT JOIN tabela_temp_3 ON Servico.id = tabela_temp_3.servicoID
								WHERE Servico.id IS NULL;

                		UPDATE Servico S INNER JOIN tabela_temp_4 TT ON S.id = TT.servicoID
                			SET ticket_atual = 0
                				WHERE S.id = TT.servicoID;


					  	DROP TEMPORARY TABLE IF EXISTS tabela_temp_3;
                        DROP TEMPORARY TABLE IF EXISTS tabela_temp_4;
					  END
				$$


 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				DELIMITER $$
				DROP EVENT IF EXISTS `myeventAddReputacaoFree` $$
				CREATE EVENT myeventAddReputacaoFree
					ON SCHEDULE EVERY 24 HOUR
					STARTS (TIMESTAMP(CURRENT_DATE))
					ON COMPLETION PRESERVE
					DO
					  BEGIN
					  	DROP TEMPORARY TABLE IF EXISTS tabela_temp_3;
		                CREATE TEMPORARY TABLE tabela_temp_3 engine=memory 
							SELECT U.id AS id, U.reputacao AS reputacao, Count(T.id) AS count
								FROM Utilizador U INNER JOIN Ticket T 
									ON T.utilizador_id = U.id 
								WHERE 
									T.utilizador_id = U.id AND
									T.estado = 'Inutilizado' AND
									T.data >= (TIMESTAMP(CURRENT_DATE) + INTERVAL - 1 WEEK) AND
									T.reputacao <= 1.5;
					  	
                		UPDATE Utilizador U INNER JOIN tabela_temp_3 TT ON U.id = TT.id
                			SET U.reputacao = U.reputacao + 0.5
                				WHERE U.id = TT.id AND TT.count = 0;

					  	DROP TEMPORARY TABLE IF EXISTS tabela_temp_3;
					  END
				$$









/* 
****************************************************************************************************************************
****************************************************************************************************************************
											PROCEDURES »»»»»»»»» TRIGGERS
****************************************************************************************************************************
****************************************************************************************************************************
*/
				/*
				DELIMITER $$
				DROP TRIGGER IF EXISTS `after_turnOffService` $$
				CREATE TRIGGER after_turnOffService
					BEFORE UPDATE
						ON Servico FOR EACH ROW
				BEGIN
					IF (NEW.estado = FALSE) THEN
						UPDATE Ticket 
							SET estado = 'Descartado' ,-- descartado
								observacoes = 
									COALESCE(concat(observacoes,'\nSistema fechou o ticket automaticamente pois servico foi fechado de forma forcada. Para mais informacoes contactar o servico respectivo'),
											 'Sistema fechou o ticket automaticamente pois servico foi fechado de forma forcada. Para mais informacoes contactar o servico respectivo')
                        WHERE DATE(Ticket.data) = DATE(NOW()) AND Ticket.servico_id = New.id AND 
							  Ticket.estado = 'Em Espera' AND Ticket.tempo_espera IS NULL;
						-- Converte os que estão em espera activa (e não os em atendimento) em DESCARTADOS
					END IF;
				END$$
				*/

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				/*
                DELIMITER $$
				DROP TRIGGER IF EXISTS `notUsedTicketTolerance` $$
				CREATE TRIGGER notUsedTicketTolerance
					AFTER UPDATE
						ON Ticket FOR EACH ROW
				BEGIN
					DROP TEMPORARY TABLE IF EXISTS tabela_temp_Tolerance;
					CREATE TEMPORARY TABLE tabela_temp_Tolerance engine=memory 
						SELECT T.id AS ticketID
						FROM Ticket AS T
                        WHERE T.data >= NEW.data AND T.id != NEW.id AND T.estado = 'Em Espera' AND T.tempo_medio_espera = NULL;
                    
					UPDATE Ticket Ti INNER JOIN tabela_temp TT ON Ti.id = TT.ticketID
						SET Ti.tolerancia_passagem = Ti.tolerancia_passagem + 1
					WHERE
						Ti.id IS NOT NULL AND
                        Ti.id = TT.ticketID;
                    
					UPDATE Ticket Ti INNER JOIN tabela_temp TT ON Ti.id = TT.ticketID
						SET Ti.estado = 'Inutilizado' -- inutilizado
					WHERE
						Ti.id IS NOT NULL AND
                        Ti.id = TT.ticketID AND
                        Ti.tolerancia_passagem > 3; -- 3 senhas de tolerancia
					
                    DROP TEMPORARY TABLE IF EXISTS tabela_temp_Tolerance;
				END$$
                */

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
				DELIMITER $$
                DROP TRIGGER IF EXISTS `checkNextTicket` $$
                CREATE TRIGGER checkNextTicket
                    AFTER UPDATE
                        ON Ticket FOR EACH ROW
                BEGIN
                    
                    -- ««««««««««««««««««««««« notUsedTicketTolerance »»»»»»»»»»»»»»»»»»
                    
                    DROP TEMPORARY TABLE IF EXISTS tabela_temp_cc;
                    CREATE TEMPORARY TABLE tabela_temp_cc engine=memory 
                        SELECT T.servico_id as servico_id, MIN(T.nr_acesso) AS nextAcesso 
                            FROM Ticket AS T JOIN Servico S 
                                ON S.id = T.servico_id
                            WHERE S.id = NEW.servico_id AND
                                  T.servico_id = NEW.servico_id AND
                                  T.id IS NOT NULL AND T.servico_id IS NOT NULL AND
                                  T.estado = 'Em Espera' AND 
                                  T.nr_acesso > NEW.nr_acesso AND
                                  T.id != NEW.id;
                    
                    
                    UPDATE Servico INNER JOIN tabela_temp_cc ON id = servico_id
                    SET ticket_atual = COALESCE(nextAcesso,ticket_atual);
                    
                    DROP TEMPORARY TABLE IF EXISTS tabela_temp_cc;
                END$$

