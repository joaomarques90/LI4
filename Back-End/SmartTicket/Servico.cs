using System;
using System.Globalization;

namespace SmartTicket
{
    public class Servico
    {
        private int id;
        private string nome;
        private string localizacao;
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
        
        
        public Servico(int id, string nome, string localizacao, double latitude, double longitude, string email, string telefone, TimeSpan horaAbertura, TimeSpan horaFecho, bool estado, float reputacaoMinima, int ticketAtual, string categoria)
        {
            this.id = id;
            this.nome = nome;
            this.localizacao = localizacao;
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
       

        public int get_id()
        {
            return id;
        }

        public string get_nome()
        {
            return nome;
        }

        public string get_localizacao()
        {
            return localizacao;
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
        public string ToString(){
            return this.id + "<" + this.nome + "<" + this.localizacao + "<" + this.latitude.ToString("G",CultureInfo.InvariantCulture) + "<" + this.longitude.ToString("G",CultureInfo.InvariantCulture) +
                   "<" + this.email + "<" + this.telefone + "<" + this.horaAbertura + "<" + this.horaFecho + "<" + this.estado + "<" +
                   this.reputacaoMinima.ToString("G",CultureInfo.InvariantCulture) + "<" + this.ticketAtual + "<" + this.categoria;
        }
    }
}