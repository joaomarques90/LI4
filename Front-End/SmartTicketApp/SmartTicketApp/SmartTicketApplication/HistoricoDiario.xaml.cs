using Microcharts;
using SkiaSharp;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using Entry = Microcharts.Entry;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class HistoricoDiario : ContentPage
    {
        public Servico servico;
        public List<Entry> CongestionSemanal;
        public List<Entry> AtendimentoSemanal;
        public List<Entry> TempoSemanal;
        public List<Entry> CongestionMensal;
        public List<Entry> AtendimentoMensal;
        public List<Entry> TempoMensal;
        public List<Entry> CongestionAnual;
        public List<Entry> AtendimentoAnual;
        public List<Entry> TempoAnual;
        public TcpClient client;
        public HistoricoDiario(Servico servicos, TcpClient client)
        {
            this.servico = servicos;
            this.client = client;
            InitializeComponent();
            GetHistoricoSemanal();
            GetHistoricoMensal();
            GetHistoricoAnual();
        }

        private string intToDayOfTheWeek(int dia)
        {
            if (dia == 1) return "2ªFeira";
            if (dia == 2) return "3ªFeira";
            if (dia == 3) return "4ªFeira";
            if (dia == 4) return "5ªFeira";
            if (dia == 5) return "6ªFeira";
            if (dia == 6) return "Sábado";
            if (dia == 0) return "Domingo";
            return "Invalido";
        }
        private void GetHistoricoSemanal()
        {
            SKColor cor = SKColor.Parse("#0027b6");
            List<Entry> Congestao = new List<Entry>();
            List<Entry> Atendimento = new List<Entry>();
            List<Entry> Tempo = new List<Entry>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "historicoDiario/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumEntries")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringHistorico = sr.ReadLine();
                    Console.WriteLine("received: " + stringHistorico + "\n");
                    string[] historicoArray = stringHistorico.Split('/');
                    double tempoMedioEspera;
                    if (String.IsNullOrEmpty(historicoArray[0]))
                        tempoMedioEspera = 0;
                    else tempoMedioEspera = double.Parse(historicoArray[0]);
                    int congestao = int.Parse(historicoArray[1]);
                    double atendimento;
                    if (String.IsNullOrEmpty(historicoArray[2])) atendimento = 0;
                    else atendimento = double.Parse(historicoArray[2]);
                    string label = intToDayOfTheWeek(int.Parse(historicoArray[3]));
                    Entry tempoM = new Entry((float)tempoMedioEspera) { Color = cor, Label = label, ValueLabel = tempoMedioEspera.ToString() };
                    Entry cong = new Entry((float)congestao) { Color = cor, Label = label, ValueLabel = congestao.ToString("G",System.Globalization.CultureInfo.InvariantCulture) };
                    Entry atend = new Entry((float)atendimento) { Color = cor, Label = label, ValueLabel = atendimento.ToString("G", System.Globalization.CultureInfo.InvariantCulture) };

                    Congestao.Add(cong);
                    Atendimento.Add(atend);
                    Tempo.Add(tempoM);
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                this.CongestionSemanal = Congestao;
                this.AtendimentoSemanal = Atendimento;
                this.TempoSemanal = Tempo;
                Chart1.Chart = new BarChart() { Entries = this.CongestionSemanal };
                Chart2.Chart = new BarChart() { Entries = this.AtendimentoSemanal };
                Chart3.Chart = new BarChart() { Entries = this.TempoSemanal };
                Chart1.Chart.LabelTextSize = 32;
                Chart2.Chart.LabelTextSize = 32;
                Chart3.Chart.LabelTextSize = 32;

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void GetHistoricoMensal()
        {
            SKColor cor = SKColor.Parse("#019a76");
            List<Entry> Congestao = new List<Entry>();
            List<Entry> Atendimento = new List<Entry>();
            List<Entry> Tempo = new List<Entry>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "historicoMensal/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumEntries")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringHistorico = sr.ReadLine();
                    Console.WriteLine("received: " + stringHistorico + "\n");
                    string[] historicoArray = stringHistorico.Split('/');
                    double tempoMedioEspera;
                    if (String.IsNullOrEmpty(historicoArray[0]))
                        tempoMedioEspera = 0;
                    else tempoMedioEspera = double.Parse(historicoArray[0]);
                    int congestao = int.Parse(historicoArray[1]);
                    double atendimento;
                    if (String.IsNullOrEmpty(historicoArray[2])) atendimento = 0;
                    else atendimento = double.Parse(historicoArray[2]);
                    string label = int.Parse(historicoArray[3]).ToString();
                    Entry tempoM = new Entry((float)tempoMedioEspera) { Color = cor, Label = label, ValueLabel = tempoMedioEspera.ToString() };
                    Entry cong = new Entry((float)congestao) { Color = cor, Label = label, ValueLabel = congestao.ToString("G", System.Globalization.CultureInfo.InvariantCulture) };
                    Entry atend = new Entry((float)atendimento) { Color = cor, Label = label, ValueLabel = atendimento.ToString("G", System.Globalization.CultureInfo.InvariantCulture) };

                    Congestao.Add(cong);
                    Atendimento.Add(atend);
                    Tempo.Add(tempoM);
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                this.CongestionMensal = Congestao;
                this.AtendimentoMensal = Atendimento;
                this.TempoMensal = Tempo;
                Chart4.Chart = new BarChart() { Entries = this.CongestionMensal };
                Chart5.Chart = new BarChart() { Entries = this.AtendimentoMensal };
                Chart6.Chart = new BarChart() { Entries = this.TempoMensal };
                Chart4.Chart.LabelTextSize = 32;
                Chart5.Chart.LabelTextSize = 32;
                Chart6.Chart.LabelTextSize = 32;

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void GetHistoricoAnual()
        {
            SKColor cor = SKColor.Parse("#f57510");
            List<Entry> Congestao = new List<Entry>();
            List<Entry> Atendimento = new List<Entry>();
            List<Entry> Tempo = new List<Entry>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "historicoAnual/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumEntries")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringHistorico = sr.ReadLine();
                    Console.WriteLine("received: " + stringHistorico + "\n");
                    string[] historicoArray = stringHistorico.Split('/');
                    double tempoMedioEspera;
                    if (String.IsNullOrEmpty(historicoArray[0]))
                        tempoMedioEspera = 0;
                    else tempoMedioEspera = double.Parse(historicoArray[0]);
                    int congestao = int.Parse(historicoArray[1]);
                    double atendimento;
                    if (String.IsNullOrEmpty(historicoArray[2])) atendimento = 0;
                    else atendimento = double.Parse(historicoArray[2]);
                    string label = int.Parse(historicoArray[3]).ToString();
                    Entry tempoM = new Entry((float)tempoMedioEspera) { Color = cor, Label = label, ValueLabel = tempoMedioEspera.ToString() };
                    Entry cong = new Entry((float)congestao) { Color = cor, Label = label, ValueLabel = congestao.ToString("G", System.Globalization.CultureInfo.InvariantCulture) };
                    Entry atend = new Entry((float)atendimento) { Color = cor, Label = label, ValueLabel = atendimento.ToString("G", System.Globalization.CultureInfo.InvariantCulture) };

                    Congestao.Add(cong);
                    Atendimento.Add(atend);
                    Tempo.Add(tempoM);
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                this.CongestionAnual = Congestao;
                this.AtendimentoAnual = Atendimento;
                this.TempoAnual = Tempo;
                Chart7.Chart = new BarChart() { Entries = this.CongestionAnual };
                Chart8.Chart = new BarChart() { Entries = this.AtendimentoAnual };
                Chart9.Chart = new BarChart() { Entries = this.TempoAnual };
                Chart7.Chart.LabelTextSize = 32;
                Chart8.Chart.LabelTextSize = 32;
                Chart9.Chart.LabelTextSize = 32;

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }


    }
}