import unittest
from unittest.mock import MagicMock
from notificacion import Notificacion

class TestNotificacion(unittest.TestCase):

    def test_enviar_alerta_correctamente(self):
        notificacion = Notificacion()

        notificacion.servicio.enviar_mensaje = MagicMock(return_value=True)

        resultado = notificacion.enviar_alerta("usuario@test.com")

        self.assertEqual(resultado, "Notificación enviada")
        notificacion.servicio.enviar_mensaje.assert_called_once()
        notificacion.servicio.enviar_mensaje.assert_called_with(
            "usuario@test.com",
            "Alerta del sistema"
        )

    def test_enviar_alerta_error_servicio(self):
        notificacion = Notificacion()

        notificacion.servicio.enviar_mensaje = MagicMock(return_value=False)

        resultado = notificacion.enviar_alerta("usuario@test.com")

        self.assertEqual(resultado, "Error al enviar notificación")
        notificacion.servicio.enviar_mensaje.assert_called_once_with(
            "usuario@test.com",
            "Alerta del sistema"
        )

    def test_enviar_alerta_excepcion_servicio(self):
        notificacion = Notificacion()

        notificacion.servicio.enviar_mensaje = MagicMock(
        side_effect=Exception("Fallo del servicio")
    )

        resultado = notificacion.enviar_alerta("usuario@test.com")

        self.assertEqual(resultado, "Error en el servicio de mensajería")
        notificacion.servicio.enviar_mensaje.assert_called_once_with(
            "usuario@test.com",
            "Alerta del sistema"
    )
if __name__ == "__main__":
    unittest.main()