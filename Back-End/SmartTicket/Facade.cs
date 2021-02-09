using System;
using System.Collections.Generic;
using MySql.Data.MySqlClient;

namespace SmartTicket
{
    public class Facade
    {
        // variaveis de instancia
        private ServicoDAO servicoDAO;
        private UserDAO userDAO;
        private HistoricoDAO historicoDAO;
        private EstatisticaDAO estatisticaDAO;
        private TicketDAO ticketDAO;
        
        // construtor
        public Facade() {
            this.servicoDAO = new ServicoDAO();
            this.userDAO = new UserDAO();
            this.historicoDAO = new HistoricoDAO();
            this.estatisticaDAO = new EstatisticaDAO();
            this.ticketDAO = new TicketDAO();
        }
        
        // funcionalidades
        
        // métodos relacionados com ServicoDAO 
        public List<Servico> get_servicos() {
            List<Servico> result = new List<Servico>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_servicos();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }

        public List<Servico> get_servicos_search(string palavra) {
            List<Servico> result = new List<Servico>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_servicos_search(palavra);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }

        public List<string> get_categorias() {
            List<string> result = new List<string>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_categorias();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }
        
        public List<Servico> get_servicos_categoria(string categoria) {
            List<Servico> result = new List<Servico>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_servicos_categoria(categoria);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }
        
    
        public List<string> get_localizacoes() {
            List<string> result = new List<string>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_localizacoes();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }
        
        public List<Servico> get_servicos_localizacao(string localizacao) {
            List<Servico> result = new List<Servico>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_servicos_localizacao(localizacao);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }
        
        
        public List<Servico> get_servicos_favoritos() {
            List<Servico> result = new List<Servico>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_servicos_favoritos();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }

        public void add_servico_favorito(int id_servico) {
            try {
                this.servicoDAO.open_connection();
                this.servicoDAO.add_servico_favoritos(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine(e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
        }
        
        public int contains_servico_favorito(int id_servico) {
            try {
                this.servicoDAO.open_connection();
                return this.servicoDAO.contains_servico_favoritos(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine(e);
                return 0;
            }
            finally {
                this.servicoDAO.close_connection();
            }
        }

        public void remove_servico_favorito(int id_servico) {
            try {
                this.servicoDAO.open_connection();
                this.servicoDAO.remove_servico_favorito(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine(e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
        }
        public List<Servico> get_servicos_usados_recentemente() {
            List<Servico> result = new List<Servico>();
            try {
                this.servicoDAO.open_connection();
                result = this.servicoDAO.get_servicos_usados_recentemente();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
            return result;
        }
        public float get_classificacao_minima() {
            this.servicoDAO.open_connection();
            try
            {
                return this.servicoDAO.get_classificacao_minima();
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
                return -1;
            }
            finally
            {
                this.servicoDAO.close_connection();
            }
        }
        
        public void set_classificacao_minima(float reputacao_min) {
            this.servicoDAO.open_connection();
            try
            {
                this.servicoDAO.set_classificacao_minima(reputacao_min);
                Console.WriteLine("SUCESSO");
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally
            {
                this.servicoDAO.close_connection();
            }
        }
        
        // método que desativa/ativa funcionalidade retirar tickets num serviço
        public Boolean get_funcionalidade_retirar_tickets() {
            this.servicoDAO.open_connection();
            try {
                return this.servicoDAO.get_funcionalidade_retirar_tickets();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
                return false;
            }
            finally {
                this.servicoDAO.close_connection();
            }
        }
        
        public void set_funcionalidade_retirar_tickets(int funcionalidade) {
            this.servicoDAO.open_connection();
            try {
                this.servicoDAO.set_funcionalidade_retirar_tickets(funcionalidade);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.servicoDAO.close_connection();
            }
        }
        
        // método retorna horário de atendimento de um serviço
        public Tuple<TimeSpan,TimeSpan> get_horario_atendimento() {
            this.servicoDAO.open_connection();
            try {
                return this.servicoDAO.get_horario_atendimento();
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
                return new Tuple<TimeSpan, TimeSpan>(new TimeSpan(),new TimeSpan());
            }
            finally
            {
                this.servicoDAO.close_connection();
            }
        }
        
        // método que muda horário de atendimento de um serviço
        public int set_horario_atendimento(int hora_abertura, int min_abertura, int hora_fecho, int min_fecho) {
            this.servicoDAO.open_connection();
            try
            {
                return this.servicoDAO.set_horario_atendimento(hora_abertura, min_abertura, hora_fecho, min_fecho);
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
                return -1;
            }
            finally
            {
                this.servicoDAO.close_connection();
            }
        }
        
        
        // métodos relacionados com UserDAO 

        // referentes ao utilizador
        public void add_utilizador(int nr_user, string password) {
            this.userDAO.open_connection();
            try {
                this.userDAO.add_utilizador( nr_user, password);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
        }

        /*
         * 0 = Não existe conta
         * 1 = Passe errada
         * 2 = Login efetuado com sucesso
         */
        public int login_utilizador(int nr_user, string password) {
            try {
                this.userDAO.open_connection();
                if (this.userDAO.existe_utilizador(nr_user) == false) {
                    this.userDAO.close_connection();
                    return 0;
                }
                BD_Connection connection = new BD_Connection("U_" + nr_user, password);
                try {
                    connection.open_connection();
                    connection.close_connection();
                    this.estatisticaDAO.set_connection(connection);
                    this.historicoDAO.set_connection(connection);
                    this.servicoDAO.set_connection(connection);
                    this.ticketDAO.set_connection(connection);
                    this.userDAO.set_connection(connection);
                    return 2;
                }
                catch (Exception e) {
                    Console.WriteLine(e.ToString());
                    return 1;
                }
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
            return 0;
        }
        
        public int get_id() {
            this.userDAO.open_connection();
            int result = 0;
            try {
                result = this.userDAO.get_id();
                return result;
            }
            catch (Exception e) {
                return result;
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
        }

        
        public void altera_utilizador(string password) {
            this.userDAO.open_connection();
            MySqlTransaction trans = this.userDAO.get_connection().get_connector().BeginTransaction();
            try {
                this.userDAO.altera_utilizador(password);
                trans.Commit();
            }
            catch (Exception e) {
                trans.Rollback();
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
        }
       
        public Utilizador get_dados_utilizador() {
            this.userDAO.open_connection();
            Utilizador u = new Utilizador(0,0);
            try {
                u = this.userDAO.get_dados_utilizador();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
            return u;
        }
        
        public int tickets_a_frente(int id) {
            this.userDAO.open_connection();
            int result = 0;
            try {
                result = this.userDAO.ticket_a_frente(id);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
            return result;
        }
        public void delete_conta_utilizador() {
            this.userDAO.open_connection();
            MySqlTransaction trans = this.userDAO.get_connection().get_connector().BeginTransaction();
            try {
                this.userDAO.delete_conta_utilizador();
                trans.Commit();
            }
            catch (Exception e) {
                trans.Rollback();
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
        }
          
        public List<Funcionario> get_funcionarios() {
            this.userDAO.open_connection();
            List<Funcionario> result = new List<Funcionario>();
            try {
                result = this.userDAO.get_funcionarios();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
            return result;
        }
        
              
        
        /*
        public List<Ticket> get_tickets_atendidos_funcionario(int nr_funcionario){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atendidos_funcionario(nr_funcionario);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atuais_utilizador(int nr_utilizador) {
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atuais_utilizador(nr_utilizador);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        */

        // métodos relacionados com HistoricoDAO
        public List<Historico> get_historico_semanal(int id_servico) {
            this.historicoDAO.open_connection();
            List<Historico> result = new List<Historico>();
            try
            {
                result = this.historicoDAO.get_historico_semanal(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.historicoDAO.close_connection();
            }
            return result;
        }
        
        public List<Historico> get_historico_mensal(int id_servico) {
            this.historicoDAO.open_connection();
            List<Historico> result = new List<Historico>();
            try
            {
                result = this.historicoDAO.get_historico_mensal(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.historicoDAO.close_connection();
            }
            return result;
        }
        
        public List<Historico> get_historico_anual(int id_servico) {
            this.historicoDAO.open_connection();
            List<Historico> result = new List<Historico>();
            try
            {
                result = this.historicoDAO.get_historico_anual(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.historicoDAO.close_connection();
            }
            return result;
        }
        
        // métodos relacionados com EstatisticaDAO
        public Estatistica get_estatistica_tempo_real(int id_servico) {
            this.estatisticaDAO.open_connection();
            Estatistica result = new Estatistica(0,0,0);
            try
            {
                result = this.estatisticaDAO.get_estatistica_tempo_real(id_servico);
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally
            {
                this.estatisticaDAO.close_connection();
            }

            return result;
        }
        public Estatistica get_estatistica_diaria(int id_servico) {
            this.estatisticaDAO.open_connection();
            Estatistica result = new Estatistica(0,0,0);
            try
            {
                result = this.estatisticaDAO.get_estatistica_diaria(id_servico);
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally
            {
                this.estatisticaDAO.close_connection();
            }

            return result;
        }
        public Estatistica get_estatistica_semanal(int id_servico) {
            this.estatisticaDAO.open_connection();
            Estatistica result = new Estatistica(0,0,0);
            try
            {
                result = this.estatisticaDAO.get_estatistica_semanal(id_servico);
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally
            {
                this.estatisticaDAO.close_connection();
            }

            return result;
        }
        public Estatistica get_estatistica_mensal(int id_servico) {
            this.estatisticaDAO.open_connection();
            Estatistica result = new Estatistica(0,0,0);
            try
            {
                result = this.estatisticaDAO.get_estatistica_mensal(id_servico);
            }
            catch (Exception e)
            {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally
            {
                this.estatisticaDAO.close_connection();
            }

            return result;
        }
        
        
        // métodos relacionados com funcionario/gerente
        /*
         * 0 = Não existe conta
         * 1 = Passe errada
         * 2 = Login efetuado com sucesso como gerente
         * 3 = login efetuado com sucesso como funcionario  
         */
        public int login_gerente_func(int nr_user, string password) {
            try {
                int aux = 0;
                this.userDAO.open_connection();
                aux = userDAO.existe_gerente_func(nr_user);
                if (aux == 0) {
                    this.userDAO.close_connection();
                    return 0;
                }
                if (aux == 1) {
                    BD_Connection connection = new BD_Connection("G_" + nr_user, password);
                    try {
                        connection.open_connection();
                        connection.close_connection();
                        this.estatisticaDAO.set_connection(connection);
                        this.historicoDAO.set_connection(connection);
                        this.servicoDAO.set_connection(connection);
                        this.ticketDAO.set_connection(connection);
                        this.userDAO.set_connection(connection);
                        return 2;
                    }
                    catch (Exception e) {
                        Console.WriteLine(e.ToString());
                        return 1;
                    }
                }

                if (aux == 2) {
                    BD_Connection connection = new BD_Connection("F_" + nr_user, password);
                    try
                    {
                        connection.open_connection();
                        connection.close_connection();
                        this.estatisticaDAO.set_connection(connection);
                        this.historicoDAO.set_connection(connection);
                        this.servicoDAO.set_connection(connection);
                        this.ticketDAO.set_connection(connection);
                        this.userDAO.set_connection(connection);
                        return 3;
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e.ToString());
                        return 1;
                    }
                }
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }

            return 0;
        }
        
        public void adiciona_funcionario(int nr_telemovel, string password, string nome) {
            this.userDAO.open_connection();
            try {
                this.userDAO.adiciona_funcionario(nr_telemovel, password, nome);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
        }

        public void remove_funcionario(int id_func) {
            this.userDAO.open_connection();
            try {
                this.userDAO.remove_funcionario(id_func);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.userDAO.close_connection();
            }
        }
        // métodos relacionados com TicketDAO
        
        public List<Ticket> get_tickets_atendidos_funcionario_diario(int id_funcionario){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atendidos_funcionario_diario(id_funcionario);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atendidos_funcionario_semanal(int id_funcionario){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atendidos_funcionario_semanal(id_funcionario);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atendidos_funcionario_mensal(int id_funcionario){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atendidos_funcionario_mensal(id_funcionario);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atendidos_funcionario_anual(int id_funcionario){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atendidos_funcionario_anual(id_funcionario);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atender_func(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atender_func();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atender_gerente(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atender_gerente();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public void atender_ticket(int id_ticket) {
            this.ticketDAO.open_connection();
            try {
                this.ticketDAO.atender_ticket(id_ticket);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
        }

        public void ticket_usado(int id_ticket) {
            this.ticketDAO.open_connection();
            try {
                this.ticketDAO.ticket_usado(id_ticket);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
        }
        
        public List<Ticket> get_tickets_utilizador_diario(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_utilizador_diario();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_utilizador_semanal(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_utilizador_semanal();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_utilizador_mensal(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_utilizador_mensal();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_utilizador_anual(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_utilizador_anual();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public List<Ticket> get_tickets_atuais_utilizador(){
            this.ticketDAO.open_connection();
            List<Ticket> result = new List<Ticket>();
            try
            {
                result = this.ticketDAO.get_tickets_atuais_utilizador();
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }

        public Ticket ticket_simples(int id_servico) {
            this.ticketDAO.open_connection();
            Ticket result = new Ticket();
            try {
                result = this.ticketDAO.ticket_simples(id_servico);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public Ticket ticket_automatico(int id_servico,string info) {
            this.ticketDAO.open_connection();
            Ticket result = new Ticket();
            try {
                result = this.ticketDAO.ticket_automatico(id_servico,info);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
            return result;
        }
        
        public void cancelar_ticket(int id_ticket) {
            this.ticketDAO.open_connection();
            try {
                this.ticketDAO.cancelar_ticket(id_ticket);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
        }
        
        public void cancelar_ticket_automatico(int id_ticket) {
            this.ticketDAO.open_connection();
            try {
                this.ticketDAO.cancelar_ticket_automatico(id_ticket);
            }
            catch (Exception e) {
                Console.WriteLine("O seguinte erro ocorreu: " + e);
            }
            finally {
                this.ticketDAO.close_connection();
            }
        }
        

    }
}