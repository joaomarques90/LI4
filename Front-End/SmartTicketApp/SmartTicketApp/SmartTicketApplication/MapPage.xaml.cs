using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using Plugin.Geolocator;
using Plugin.Geolocator.Abstractions;
using Plugin.Permissions;
using Plugin.Permissions.Abstractions;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using System.IO;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class MapPage : ContentPage
    {
        private TcpClient client;
        private bool hasLocationPermission = false;
        private string localizacao;
        private string categoria;
        private string filtro = "all";
        private double latitude = 0;
        private double longitude = 0;
        public MapPage(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
            GetPermissions();
            List<Servico> servicos = GetServicos();
            servicosListView.ItemsSource = servicos;
           DisplayInMap(servicos);
        }


        private async void GetPermissions()
        {
            try
            {
                var status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.LocationWhenInUse);
                if (status != PermissionStatus.Granted)
                {
                    if (await CrossPermissions.Current.ShouldShowRequestPermissionRationaleAsync(Permission.LocationWhenInUse))
                    {
                        await DisplayAlert("Need your location", "We need to access your location", "Ok");
                    }

                    var results = await CrossPermissions.Current.RequestPermissionsAsync(Permission.LocationWhenInUse);
                    if (results.ContainsKey(Permission.LocationWhenInUse))
                        status = results[Permission.LocationWhenInUse];
                }

                if (status == PermissionStatus.Granted)
                {
                    hasLocationPermission = true;
                    locationsMap.IsShowingUser = true;

                    GetLocation();
                }
                else
                {
                    await DisplayAlert("Location denied", "You didn't give us permission to access location, so we can't show you where you are", "Ok");
                }
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message, "Ok");
            }
        }
        protected override async void OnAppearing()
        {
            base.OnAppearing();

            if (hasLocationPermission)
            {
                var locator = CrossGeolocator.Current;

                locator.PositionChanged += Locator_PositionChanged;
                await locator.StartListeningAsync(TimeSpan.Zero, 100);
            }

            GetLocation();
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            CrossGeolocator.Current.StopListeningAsync();
            CrossGeolocator.Current.PositionChanged -= Locator_PositionChanged;
        }

        void Locator_PositionChanged(object sender, Plugin.Geolocator.Abstractions.PositionEventArgs e)
        {
            MoveMap(e.Position);
        }

        private async void GetLocation()
        {
            if (hasLocationPermission)
            {
                var locator = CrossGeolocator.Current;
                var position = await locator.GetPositionAsync();
                this.latitude = position.Latitude;
                this.longitude = position.Longitude;

                MoveMap(position);
            }
        }

        private void MoveMap(Position position)
        {
            var center = new Xamarin.Forms.Maps.Position(position.Latitude, position.Longitude);
            var span = new Xamarin.Forms.Maps.MapSpan(center, 1, 1);
            locationsMap.MoveToRegion(span);
        }

        private void DisplayInMap(List<Servico> servicos)
        {
            foreach (var servico in servicos)
            {
                try
                {
                    var position = new Xamarin.Forms.Maps.Position(servico.get_latitude(), servico.get_longitude());
                    var pin = new Xamarin.Forms.Maps.Pin()
                    {
                        Type = Xamarin.Forms.Maps.PinType.SavedPin,
                        Position = position,
                        Label = servico.NomeServico,
                        Address = servico.Address
                    };
                    locationsMap.Pins.Add(pin);
                }
                catch (NullReferenceException nre) { Console.WriteLine(nre.StackTrace); }
                catch (Exception ex) { Console.WriteLine(ex.StackTrace); }
            }
        }



        private async void servicosListView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem == null)
            {
                return;
            }
            
            
            var selectedService = e.SelectedItem as Servico;
            await Navigation.PushAsync(new MenuServices(selectedService, this.client,this.latitude,this.longitude));
            servicosListView.SelectedItem = null;
            if (filtro.Equals("all")) servicosListView.ItemsSource = GetServicos();
            if (filtro.Equals("favoritos")) servicosListView.ItemsSource = GetFavoritos();
            if (filtro.Equals("recentes")) servicosListView.ItemsSource = GetUsadosRecentemente();
            if (filtro.Equals("categoria")) servicosListView.ItemsSource = filterCategoria(this.categoria);
            if (filtro.Equals("localizacao")) servicosListView.ItemsSource = filterLocalizacao(this.localizacao);

        }

        private List<string> GetCategorias()
        {
            List<string> categorias = new List<string>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getCategorias/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumCategorias")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringCategoria = sr.ReadLine();
                    Console.WriteLine("received: " + stringCategoria + "\n");
                    categorias.Add(stringCategoria);
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return categorias;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private List<Servico> filterCategoria(string categoria)
        {
            List<Servico> servicos = new List<Servico>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getServicosCategoria/" + categoria + "/";
                sw.WriteLine(request);
                sw.Flush();
                string line = sr.ReadLine();
                string[] resultado = line.Split('/');
                if (resultado[0].Equals("RespostaNumServicos")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string lineServico = sr.ReadLine();
                    servicos.Add(Servico.stringToServico(lineServico));
                    result--;
                }
                return servicos;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private List<Servico> GetFavoritos()
        {
            List<Servico> servicos = new List<Servico>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getFavoritos/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumFavoritos")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringServico = sr.ReadLine();
                    Console.WriteLine("received: " + stringServico + "\n");
                    servicos.Add(Servico.stringToServico(stringServico));
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return servicos;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private List<Servico> GetUsadosRecentemente()
        {
            List<Servico> servicos = new List<Servico>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getUsadosRecentemente/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumServicos")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringServico = sr.ReadLine();
                    Console.WriteLine("received: " + stringServico + "\n");
                    servicos.Add(Servico.stringToServico(stringServico));
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return servicos;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private async void Filtrar_Clicked(object sender, EventArgs e)
        {
            string result = await DisplayActionSheet("Escolha uma opção", "Ok", "Cancelar","Favoritos", "Categoria", "Usados Recentemente", "Localização","Sem Filtro");
             if (result.Equals("Favoritos"))
            {
                List<Servico> servicos = GetFavoritos();
                servicosListView.ItemsSource = servicos;
                filtro = "favoritos";
            }
            else if(result.Equals("Usados Recentemente"))
            {
                List<Servico> servicos = GetUsadosRecentemente();
                servicosListView.ItemsSource = servicos;
                filtro = "recentes";
            }
            else if (result.Equals("Categoria"))
            {
                List<string> categorias = GetCategorias();
                await Navigation.PushModalAsync(new SelecionarCategoria(this, categorias));
                filtro = "categoria";
            }
            else if (result.Equals("Localização"))
            {
                List<string> localizacoes = GetLocalizacoes();
                await Navigation.PushModalAsync(new SelecionarLocalizacao(this,  localizacoes));
                filtro = "localizacao";
            }
            else if (result.Equals("Sem Filtro"))
            {
                servicosListView.ItemsSource = GetServicos();
                filtro = "all";
            }

            return;
        }

        
        
        
        public async void categorySelected(String categoria)
        {
            if (String.IsNullOrEmpty(categoria)) ;
            else
            {
                this.categoria = categoria;
                List<Servico> servicos = filterCategoria(categoria);
                servicosListView.ItemsSource = servicos;

            }
        }

     
        private List<string> GetLocalizacoes()
        {
            List<string> localizacoes = new List<string>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getLocalizacoes/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumLocalizacoes")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringLocalizacoes = sr.ReadLine();
                    Console.WriteLine("received: " + stringLocalizacoes + "\n");
                    localizacoes.Add(stringLocalizacoes);
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return localizacoes;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private List<Servico> filterLocalizacao(string localizacao)
        {
            List<Servico> servicos = new List<Servico>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getServicosLocalizacao/" + localizacao + "/";
                sw.WriteLine(request);
                sw.Flush();
                string line = sr.ReadLine();
                string[] resultado = line.Split('/');
                if (resultado[0].Equals("RespostaNumServicos")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string lineServico = sr.ReadLine();
                    servicos.Add(Servico.stringToServico(lineServico));
                    result--;
                }
                return servicos;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        public async void localizationSelected(String localizacao)
        {
            if (String.IsNullOrEmpty(localizacao)) ;
            else
            {
                this.localizacao = localizacao;
                List<Servico> servicos = filterLocalizacao(localizacao);
                servicosListView.ItemsSource = servicos;
            }
        }

        private void SearchBar_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (e.NewTextValue == null) ;
            else servicosListView.ItemsSource = GetServicosSearchBar(e.NewTextValue);
        }


        private List<Servico> GetServicos()
        {
            List<Servico> servicos = new List<Servico>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request ="getServicos/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumServicos")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringServico = sr.ReadLine();
                    Console.WriteLine("received: " + stringServico + "\n");
                    servicos.Add(Servico.stringToServico(stringServico));
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return servicos;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private List<Servico> GetServicosSearchBar(string search){
            List<Servico> servicos = new List<Servico>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getServicosSearch/"+search+"/";
                sw.WriteLine(request);
                sw.Flush();
                string line = sr.ReadLine();
                string[] resultado = line.Split('/');
                if (resultado[0].Equals("RespostaNumServicos")) { result = int.Parse(resultado[1]);}

                while (result > 0)
                {
                    string lineServico = sr.ReadLine();
                    servicos.Add(Servico.stringToServico(lineServico));
                    result--;
                }
                return servicos;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void SearchBar_SearchButtonPressed(object sender, EventArgs e)
        {
            servicosListView.ItemsSource = GetServicosSearchBar(searchBar.Text);
        }

        private void ServicosListView_OnRefreshing(object sender, EventArgs e){

            if(filtro.Equals("all")) servicosListView.ItemsSource = GetServicos();
            if (filtro.Equals("favoritos")) servicosListView.ItemsSource = GetFavoritos();
            if (filtro.Equals("recentes")) servicosListView.ItemsSource = GetUsadosRecentemente();
            if (filtro.Equals("categoria")) servicosListView.ItemsSource = filterCategoria(this.categoria);
            if (filtro.Equals("localizacao")) servicosListView.ItemsSource = filterLocalizacao(this.localizacao);
            servicosListView.EndRefresh();
        }
    }
}

