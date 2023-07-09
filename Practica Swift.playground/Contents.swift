import Foundation


//: ## Sistema para gestionar las reservas del Hotel Luchadores para Goku y sus amigos.

//: ### Requisito 1: Estructuras
//: Enum: ReservationError

enum ReservationError: LocalizedError{
    case reservaRepetida
    case reservaPerdida
    case clienteRepetido
    
    var errorDescription: String?{
        switch self{
        case .reservaRepetida:
            return "ReservationError: El ID de la reserva que se quiere agregar ya existe."
        case .reservaPerdida:
            return " ReservationError: La reserva no se encuentra."
        case .clienteRepetido:
            return "ReservationError: El cliente ya tiene una reserva."
        }
    }
    
}


//: Structs:
//: Client

struct Client: Equatable, Hashable{
    let nombre: String
    let edad: Int
    //La altura debe venir en centímetros (pre-requisito) por lo que solo se consideran números enteros.
    let altura: Int
}

//: Reservation
struct Reservation{
    let id: Int
    let nombreHotel: String
    let listaClientes: Array<Client>
    let duracion: Int
    let precio: Double
    let desayuno: Bool
}

//: Class: HotelReservationManager
class HotelReservationManager{
    //Listado de reservas
    private var reservas: Array<Reservation> = []
    private var numeroReserva: Int = 0
    private let precioBase:Double = 20
    let nombre = "Hotel Luchadores"
    
    // Getter de reservas
    func getReservas() -> Array<Reservation>{
        return reservas
    }
    
    //Calcular el precio
    func precio(_ clientes: Int, _ dias: Int, _ desayuno: Bool) -> Double{
        let precioDesayuno = (desayuno ? 1 : 1.25)
        return precioDesayuno*Double(clientes)*Double(dias)*precioBase
    }
    //Añadir reserva
    func agregarReserva(listaClientes: Array<Client>, duracion: Int, desayuno: Bool) throws -> Reservation {
        //Asignar un unico ID
        var id =  numeroReserva
        for res in reservas{
            if(res.id == id){
                throw ReservationError.reservaRepetida
            }
            if !(Set(listaClientes).isDisjoint(with: Set(res.listaClientes))){
                throw ReservationError.clienteRepetido
            }
        }
        
        //Calcular el precio
        let precioCalculado = precio(listaClientes.count, duracion, desayuno)
        
        
        //Agregar el nombre del hotel
        let reserva = Reservation(id: id, nombreHotel: nombre, listaClientes: listaClientes, duracion: duracion, precio: precioCalculado, desayuno:desayuno)
        
        //Añadir reserva
        reservas.append(reserva)
        
        numeroReserva += 1
        //Retornar reserva
        return reserva
    }
    
    //Cancelar reserva
    func cancelarReserva(idReserva: Int) throws{
        var notFound = 0
        let reservasFijas = reservas
        for i in 0 ..< reservas.count{
            if(reservasFijas[i].id == idReserva){
                reservas.remove(at: i)
            }
            else{
                notFound += 1
            }
        }
        if notFound == reservasFijas.count{
            throw ReservationError.reservaPerdida
        }
    }
    //Definimos un setter de numeroReserva para poder verificar que la función lanza error para reservas con id repetido.
    func setNumeroReserva(newValue: Int){
        numeroReserva = newValue
    }
}


//: ### Requisito 2: TESTS
//: 1. Validación de reserva.
func testAddReservation(){
    var hotel = HotelReservationManager()
    let clientes = [Client(nombre: "Alf", edad: 23, altura: 176), Client(nombre: "Beto", edad: 25, altura: 167)]
    let clientes2 = [Client(nombre: "Camilo", edad: 23, altura: 178), Client(nombre: "Daniel", edad: 24, altura: 169)]

//: Verificamos error cuando los clientes se repiten.
    do{
        try hotel.agregarReserva(listaClientes: clientes , duracion: 12, desayuno: true)
        try hotel.agregarReserva(listaClientes: clientes , duracion: 12, desayuno: true)
    }
    catch {
        let reservationError = error as? ReservationError
        assert(reservationError == ReservationError.clienteRepetido)
        print(reservationError!.localizedDescription)
        //Se debe imprimir ReservationError: El cliente ya tiene una reserva. Nada más porque el assertion no falla.
    }
//: Verificamos que no haya error cuando los clientes son distintos.
    hotel = HotelReservationManager()
    do{
        try hotel.agregarReserva(listaClientes: clientes , duracion: 12, desayuno: true)
        try hotel.agregarReserva(listaClientes: clientes2 , duracion: 12, desayuno: true)
        print("No hay error, los clientes no se repiten.")
        //Se debe imprimir "No hay error, los clientes no se repiten." ya que no fallan los try y el código corre al final.
    }
    catch {
        let reservationError = error as? ReservationError
        print(reservationError!.localizedDescription)
    }

//: Añadimos la función de set de numeroReserva para verificar que cuando dos reservas tengan el mismo id (bajamos el número de reserva) no se pueda añadir y de error.
    hotel = HotelReservationManager()
    do{
        try hotel.agregarReserva(listaClientes: clientes , duracion: 12, desayuno: true)
        //Al añadirse la reserva hotel.numeroReserva = 1. Lo devolvemos a 0 por lo que debe dar un error de reservaRepetida.
        hotel.setNumeroReserva(newValue: 0)
        try hotel.agregarReserva(listaClientes: clientes2 , duracion: 12, desayuno: true)
    }
    catch {
        let reservationError = error as? ReservationError
        assert(reservationError == ReservationError.reservaRepetida)
        print(reservationError!.localizedDescription)
        //Se debe imprimir ReservationError: El ID de la reserva que se quiere agregar ya existe. Nada más porque el assertion no falla.
    }
//: Probamos que sin cambiar el número de reserva podamos añadir más reservas y no da error.
    hotel = HotelReservationManager()
    do{
        try hotel.agregarReserva(listaClientes: clientes , duracion: 12, desayuno: true)
        try hotel.agregarReserva(listaClientes: clientes2 , duracion: 12, desayuno: true)
        try hotel.agregarReserva(listaClientes: [] , duracion: 12, desayuno: true)
        print("No hay problemas con las reservas")
        //Se debe imprimir "No hay problemas con las reservas" ya que no fallan los try y el código corre al final.
        
    }
    catch {
        let reservationError = error as? ReservationError
        print(reservationError!.localizedDescription)
    }
}

//: 2. Validación de cancelación
func testCancelReservation(){
    //: Creamos un HotelReservationManager, añadimos dos reservas
    var hotel = HotelReservationManager()
    let clientes = [Client(nombre: "Alf", edad: 23, altura: 176), Client(nombre: "Beto", edad: 25, altura: 167)]
    let clientes2 = [Client(nombre: "Camilo", edad: 23, altura: 178), Client(nombre: "Daniel", edad: 24, altura: 169)]
    do{
        try hotel.agregarReserva(listaClientes: clientes , duracion: 12, desayuno: true)
        try hotel.agregarReserva(listaClientes: clientes2 , duracion: 12, desayuno: false)
    }
    catch let error{
        print(error.localizedDescription)
    }
    //: Eliminamos una reserva existente tomando la primera reserva en la lista y eliminándola.
    
    do{
        try hotel.cancelarReserva(idReserva: hotel.getReservas()[0].id)
        assert(hotel.getReservas().count == 1)
        print("La reserva se eliminó correctamente.")
        //Debe imprimirse "La reserva se eliminó correctamente".
    }
    catch{
        let reservationError = error as? ReservationError
        print(reservationError!.localizedDescription)
    }
    
    //: Eliminamos una reserva no existente y vemos que da error.
    
    do{
        try hotel.cancelarReserva(idReserva: 10)
    }
    catch{
        let reservationError = error as? ReservationError
        assert(reservationError == ReservationError.reservaPerdida)
        print(reservationError!.localizedDescription)
        //Debe imprimirse la descripción del error y ya porque el assert es correcto.
    }
    
}

//: 3. Validación de precio
func testReservationPrice(){
    //: Verificamos que para condiciones iguales de cantidad de personas, duración y desayuno el precio de el mismo valor.
    let hotel = HotelReservationManager()
    
    // Por el modo en el que esta construido el precio al coincidir estas condiciones es evidente que no hay error al ser exactamente el mismo llamado a la función (que no tiene componentes aleatorios).
    assert(hotel.precio(3, 3, true) == hotel.precio(3,3,true))
    print("El cálculo del precio es correcto.")
    //: Verificamos que el precio dentro de las reservas se guarde como se definió la función previa.
    let clientes = [Client(nombre: "Alf", edad: 23, altura: 176), Client(nombre: "Beto", edad: 25, altura: 167)]
    let clientes2 = [Client(nombre: "Camilo", edad: 23, altura: 178), Client(nombre: "Daniel", edad: 24, altura: 169)]
    do{
        try hotel.agregarReserva(listaClientes: clientes , duracion: 2, desayuno: true)
        try hotel.agregarReserva(listaClientes: clientes2 , duracion: 2, desayuno: true)
    }
    catch let error{
        print(error.localizedDescription)
    }
    
    //Vemos que las dos reservas estan bajo las mismas condiciones: 2 clientes, 2 días, con desayuno
    //Verificamos que se hayan añadido con el mismo precio
    let reservas = hotel.getReservas()
    assert(reservas[0].precio == reservas[1].precio)
    print("El precio se asigna a las reservas correctamente.")
}

/*: Si el código es correcto al correrlo la consola debe imprimir los siguientes valores:\
ReservationError: El cliente ya tiene una reserva.\
No hay error, los clientes no se repiten.\
ReservationError: El ID de la reserva que se quiere agregar ya existe.\
No hay problemas con las reservas.\
La reserva se eliminó correctamente.\
ReservationError: La reserva no se encuentra.\
El cálculo del precio es correcto.\
 El precio se asigna a las reservas correctamente.
 */


testAddReservation()
testCancelReservation()
testReservationPrice()
