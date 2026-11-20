class Matematica:
    @staticmethod
    def mcd(a, b):
        a = abs(a)
        b = abs(b)

        while b != 0:
            temp = b
            b = a % b
            a = temp

        return a