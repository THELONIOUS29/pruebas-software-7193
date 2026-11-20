from servicio_mensajeria import ServicioMensajeria

class Notificacion:
    def __init__(self):
        self.servicio = ServicioMensajeria()

    def enviar_alerta(self, usuario):
        if not usuario:
            return "Usuario inválido"

        try:
            enviado = self.servicio.enviar_mensaje(usuario, "Alerta del sistema")
        except Exception:
            return "Error en el servicio de mensajería"

        if enviado:
            return "Notificación enviada"
        
        return "Error al enviar notificación"