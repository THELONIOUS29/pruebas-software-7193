"""Escenario 2: Caja Blanca - Calculo de descuento en carrito de compras."""


def aplicar_descuento(total_compra):
    """Aplica el descuento correspondiente y devuelve el total final."""
    if 100 <= total_compra < 200:
        return total_compra * 0.90
    if total_compra >= 200:
        return total_compra * 0.80
    return total_compra


def main():
    print("Calculo de descuento en carrito de compras")
    total_compra = float(input("Ingrese el total de la compra: "))
    total_final = aplicar_descuento(total_compra)
    descuento = total_compra - total_final

    print(f"Total original: ${total_compra:.2f}")
    print(f"Descuento aplicado: ${descuento:.2f}")
    print(f"Total a pagar: ${total_final:.2f}")


if __name__ == "__main__":
    main()
