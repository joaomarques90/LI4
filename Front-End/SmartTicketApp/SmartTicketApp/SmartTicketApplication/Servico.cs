
using System;

namespace SmartTicketApplication
{
    public class Servico
    {
        private int id;
        public string NomeServico { get; set; }
        public string Address {get;set;}
        private double latitude;
        private double longitude;
        private string email;
        private string telefone;
        private TimeSpan horaAbertura;
        private TimeSpan horaFecho;
        private Boolean estado;
        private float reputacaoMinima;
        private int ticketAtual;
        private string categoria;

        public Servico(int id, string NomeServico, string Address, double latitude, double longitude, string email, string telefone, TimeSpan horaAbertura, TimeSpan horaFecho, bool estado, float reputacaoMinima, int ticketAtual, string categoria)
        {
            this.id = id;
            this.NomeServico = NomeServico;
            this.Address = Address;
            this.latitude = latitude;
            this.longitude = longitude;
            this.email = email;
            this.telefone = telefone;
            this.horaAbertura = horaAbertura;
            this.horaFecho = horaFecho;
            this.estado = estado;
            this.reputacaoMinima = reputacaoMinima;
            this.ticketAtual = ticketAtual;
            this.categoria = categoria;
        }

        static public Servico stringToServico(string input)
        {
            String[] resultado = input.Split('<');
            return new Servico(int.Parse(resultado[0]), resultado[1], resultado[2], double.Parse(resultado[3]), double.Parse(resultado[4]), resultado[5], resultado[6], TimeSpan.Parse(resultado[7]),
                TimeSpan.Parse(resultado[8]), bool.Parse(resultado[9]), float.Parse(resultado[10]), int.Parse(resultado[11]), resultado[12]);
        }
        public int get_id()
        {
            return id;
        }

       

        public double get_latitude()
        {
            return latitude;
        }
        public double get_longitude()
        {
            return longitude;
        }
        public string get_email()
        {
            return email;
        }
        public string get_telefone()
        {
            return telefone;
        }

        public TimeSpan get_horaAbertura()
        {
            return horaAbertura;
        }

        public TimeSpan get_horaFecho()
        {
            return horaFecho;
        }

        public Boolean get_estado()
        {
            return estado;
        }

        public float get_reputacaoMinima()
        {
            return reputacaoMinima;
        }

        public int get_ticketAtual()
        {
            return ticketAtual;
        }
        public string get_categoria()
        {
            return categoria;
        }
        public string ToString() {
            return "ID= " + this.id + " " + "NomeServico= " + this.NomeServico + " " + "LATITUDE= " + this.latitude + " " +"LONGITUDE= " + this.longitude + "\n";
        }
    }
}