
-- ------------------------------------------------------
-- ------------------------------------------------------
-- Universidade do Minho
-- Mestrado Integrado em Engenharia Informática (MiEI)
-- Unidade Curricular de Laboratórios de Informática IV (LI4)
-- 
-- Caso de Estudo: IQueue
-- Criação utilizador guestSMS
--
-- Março/2020
-- Grupo 2, Turno 2
-- ------------------------------------------------------
-- ------------------------------------------------------

/* 

								***************************** SMS *****************************

	Conta para a WEB-API (php) que conecta à BD e actualiza os valores relativos ao SMS.
	Visto ser um site na internet (público) quero guardar qualquer erro de "get", seja fidedigno ou não.
    
*/
		USE iqueue;
		-- CREATE ROLE 'utilizador', 'guestDB';
		
		DROP USER IF EXISTS 'guestSMS'@'%';
		CREATE USER 'guestSMS'@'%' IDENTIFIED WITH mysql_native_password BY 'uminho2020_SMS';


		GRANT INSERT,SELECT ON iqueue.SMS_SERVER_FailedWebRequest TO 'guestSMS'@'%'; 
		GRANT INSERT,SELECT ON iqueue.FailedWebRequest TO 'guestSMS'@'%'; 
		GRANT INSERT,UPDATE,SELECT ON iqueue.SMS TO 'guestSMS'@'%';

		FLUSH PRIVILEGES;
