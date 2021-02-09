using System.Globalization;

namespace SmartTicket
{
    public class Utilizador : User
    {
        // variaveis de instancia
        private float reputacao;
        
        // get's e set's
        public void set_reputacao(float r) {
            this.reputacao = r;
        }
        
        public float get_reputacao() {
            return this.reputacao;
        }

        // construtor
        public Utilizador(int nr, float r)
        {
            this.set_nr_telemovel(nr);
            this.reputacao = r;
        }

        public override string ToString(){
            return this.get_nr_telemovel() + "/" + this.reputacao.ToString("G", CultureInfo.InvariantCulture);
        }
    }
}