
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


SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema iqueue
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema iqueue
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `iqueue`;
CREATE SCHEMA IF NOT EXISTS `iqueue` DEFAULT CHARACTER SET utf8mb4 ;
USE `iqueue` ;

-- -----------------------------------------------------
-- Table `iqueue`.`Utilizador`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Utilizador` (
  `id` INT NOT NULL AUTO_INCREMENT, -- id Unico no Sistema
  `nr_telemovel` INT NOT NULL,
  `pass` BLOB  NOT NULL,
  `reputacao` FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Servico`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Servico` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nome` VARCHAR(45) NOT NULL,
  `categoria` VARCHAR(45) NOT NULL,
  `estado` TINYINT(1) NOT NULL,
  `hora_abertura` TIME NOT NULL,
  `hora_fecho` TIME NOT NULL,
  `latitude` DOUBLE NOT NULL,
  `longitude` DOUBLE NOT NULL,
  `localizacao` VARCHAR(100) NULL,
  `reputacao_min` FLOAT NOT NULL DEFAULT 0,
  `ticket_atual` INT NULL,
  `email`        VARCHAR(255) NULL,
  `telefone`    INT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Funcionario`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Funcionario` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nr_telemovel` INT NOT NULL,
  `pass` BLOB NOT NULL,
  `servico_id` INT NOT NULL,
  `nome` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_Funcionario_Serviço1_idx` (`servico_id` ASC),
  CONSTRAINT `fk_Funcionario_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Ticket`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Ticket` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `utilizador_id` INT NOT NULL,
  `servico_id` INT NOT NULL,
  `data` DATETIME NOT NULL,
  `nr_acesso` INT NOT NULL,
  `estado` VARCHAR(45) NOT NULL,
  `tolerancia_passagem` INT NOT NULL DEFAULT 0,
  `tempo_espera` TIME NULL,
  `tempo_atendimento` TIME NULL,
  `funcionario_id` INT NULL,
  `gerente_id` INT NULL,
  `hide_ticket` TINYINT(1) NULL DEFAULT 0,
  `observacoes` VARCHAR(511) NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_Ticket_Utilizador_idx` (`utilizador_id` ASC),
  INDEX `fk_Ticket_Serviço1_idx` (`servico_id` ASC),
  INDEX `fk_Ticket_Funcionario1_idx` (`funcionario_id` ASC),
  INDEX `fk_Ticket_Gerente1_idx` (`gerente_id` ASC),
  CONSTRAINT `fk_Ticket_Utilizador`
    FOREIGN KEY (`utilizador_id`)
    REFERENCES `iqueue`.`Utilizador` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Ticket_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Ticket_Funcionario1`
    FOREIGN KEY (`funcionario_id`)
    REFERENCES `iqueue`.`Funcionario` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Ticket_Gerente1`
    FOREIGN KEY (`gerente_id`)
    REFERENCES `iqueue`.`Gerente` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Estatistica_Tempo_Real`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Estatistica_Tempo_Real` (
  `servico_id` INT NOT NULL,
  `congestao` INT NULL,
  `tempo_espera` TIME NULL,
  `tempo_atendimento` TIME NULL,
  PRIMARY KEY (`servico_id`),
  INDEX `fk_Estatistica_Tempo_Real_Serviço1_idx` (`servico_id` ASC),
  CONSTRAINT `fk_Estatistica_Tempo_Real_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Estatistica_Diaria`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Estatistica_Diaria` (
  `data` DATE NOT NULL,
  `servico_id` INT NOT NULL,
  `tempo_medio_espera` TIME NULL,
  `congestao_media` INT NULL,
  `tempo_atendimento` TIME NULL,
  PRIMARY KEY (`data`, `servico_id`),
  INDEX `fk_Historico_Diario_Serviço1_idx` (`servico_id` ASC),
  CONSTRAINT `fk_Historico_Diario_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Estatistica_Semanal`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Estatistica_Semanal` (
  `data` DATE NOT NULL,
  `servico_id` INT NOT NULL,
  `tempo_medio_espera` TIME NULL,
  `congestao_media` INT NULL,
  `tempo_atendimento` TIME NULL,
  PRIMARY KEY (`data`, `servico_id`),
  INDEX `fk_Historico_Semanal_Serviço1_idx` (`servico_id` ASC),
  CONSTRAINT `fk_Historico_Semanal_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Estatistica_Mensal`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Estatistica_Mensal` (
  `data` DATE NOT NULL,
  `servico_id` INT NOT NULL,
  `tempo_medio_espera` TIME NULL,
  `congestao_media` INT NULL,
  `tempo_atendimento` TIME NULL,
  PRIMARY KEY (`data`, `servico_id`),
  INDEX `fk_Historico_Mensal_Serviço1_idx` (`servico_id` ASC),
  CONSTRAINT `fk_Historico_Mensal_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Gerente`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Gerente` (
  `id` INT NOT NULL AUTO_INCREMENT, -- id Unico no Sistema
  `nr_telemovel` INT NOT NULL,
  `pass` BLOB NOT NULL,
  `servico_id` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_Gerente_Serviço1_idx` (`servico_id` ASC),
  CONSTRAINT `fk_Gerente_Serviço1`
    FOREIGN KEY (`servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`Utilizador_ServicosFavoritos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`Utilizador_ServicosFavoritos` (
  `Utilizador_id` INT NOT NULL,
  `Servico_id` INT NOT NULL,
  PRIMARY KEY (`Utilizador_id`, `Servico_id`),
  INDEX `fk_Utilizador_has_Servico_Servico2_idx` (`Servico_id` ASC),
  CONSTRAINT `fk_Utilizador_has_Servico_Utilizador2`
    FOREIGN KEY (`Utilizador_id`)
    REFERENCES `iqueue`.`Utilizador` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Utilizador_has_Servico_Servico2`
    FOREIGN KEY (`Servico_id`)
    REFERENCES `iqueue`.`Servico` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;



-- -----------------------------------------------------
-- Table `iqueue`.`SMS`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`SMS` (
  `sms_idx` INT NOT NULL AUTO_INCREMENT,
  `sms_id` VARCHAR(50) NOT NULL,
  `sms_to` VARCHAR(50) NOT NULL,
  `sms_from` VARCHAR(45) NOT NULL,
  `create_date` DATETIME(6) NOT NULL,
  `sms_username` VARCHAR(45) NULL,
  `sms_status` VARCHAR(45) NULL,
  `sms_status_name` VARCHAR(45) NULL,
  `sms_donedate` DATETIME NULL,
  `sms_mcc` VARCHAR(15) NULL,
  `sms_mnc` VARCHAR(15) NULL,
  `sms_content` VARCHAR(255) NULL,
  `sms_points` FLOAT NULL,
  `last_update` DATETIME(6) NULL,
  PRIMARY KEY (`sms_idx`,`sms_id`, `sms_to`,`sms_from`,`create_date`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`SMS_SERVER_FailedWebRequest`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`SMS_SERVER_FailedWebRequest` (
  `data` DATETIME(6) NOT NULL,
  PRIMARY KEY (`data`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `iqueue`.`FailedWebRequest`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `iqueue`.`FailedWebRequest` (
  `chave` VARCHAR(255) NOT NULL,
   `data` DATETIME(6) NOT NULL,
  `valor` VARCHAR(511) NULL,
  PRIMARY KEY (`data`, `chave`),
  INDEX `fk_WebRequest_Contents_SMS_SERVER_FailedWebRequest1_idx` (`data` ASC),
  CONSTRAINT `fk_WebRequest_Contents_SMS_SERVER_FailedWebRequest1`
    FOREIGN KEY (`data`)
    REFERENCES `iqueue`.`SMS_SERVER_FailedWebRequest` (`data`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
