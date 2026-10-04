"""Original bounded decoders derived from documented static behavior."""
import struct
import zlib


def read(data, offset, length):
    if offset < 0 or length < 0 or offset + length > len(data):
        raise ValueError('Read outside input')
    return data[offset:offset + length]


def word(data, offset):
    return int.from_bytes(read(data, offset, 2), 'little')


def pointer(data, offset, group):
    cpu = word(data, offset)
    if not 0x6000 <= cpu < 0xC000:
        raise ValueError('Pointer outside bank group')
    result = group + cpu - 0x6000
    read(data, result, 1)
    return result


def nibble(data, offset, index):
    value = read(data, offset + index // 2, 1)[0]
    return value & 15 if index % 2 else value >> 4


def collision_bits(data):
    if len(data) != 32:
        raise ValueError('Collision profile must contain 32 bytes')
    return [(byte >> bit) & 1 for byte in data for bit in range(7, -1, -1)]


def planar(data, bpp, colors):
    if bpp not in (1, 2, 3) or len(data) != bpp * 8 or len(colors) != 1 << bpp:
        raise ValueError('Invalid planar tile')
    return [colors[sum(((data[y*bpp+p] >> (7-x)) & 1) << p for p in range(bpp))]
            for y in range(8) for x in range(8)]


def flip_x(tile):
    if len(tile) != 64:
        raise ValueError('Invalid tile size')
    return [tile[y*8+7-x] for y in range(8) for x in range(8)]


def terminated(data, offset, width, limit, end=None):
    """Record boundary FF terminator; FF inside a record is ordinary data."""
    end = len(data) if end is None else end
    rows = []
    for _ in range(limit + 1):
        if offset >= end:
            raise ValueError('Missing terminator')
        if read(data, offset, 1)[0] == 255:
            return rows, offset + 1
        if len(rows) == limit or offset + width > end:
            raise ValueError('Record count/extent exceeds limit')
        rows.append(list(read(data, offset, width)))
        offset += width
    raise ValueError('Missing terminator')


def unpack_gfx(data, start=0, max_output=131072):
    """UnpackGfx stream to address/data chunks, not a universal graphics codec."""
    pos = start
    address = word(data, pos)
    pos += 2
    chunks, output, total = [], bytearray(), 0
    while True:
        token = read(data, pos, 1)[0]
        pos += 1
        if token == 0:
            chunks.append((address, bytes(output)))
            return chunks, pos
        if token == 128:
            chunks.append((address, bytes(output)))
            address = word(data, pos)
            pos += 2
            output = bytearray()
            continue
        size = token & 127
        total += size
        if total > max_output or address + len(output) + size > 65536:
            raise ValueError('Graphics stream exceeds output/address limit')
        if token & 128:
            output.extend(read(data, pos, size))
            pos += size
        else:
            output.extend(read(data, pos, 1) * size)
            pos += 1


def rgb_palette(register_pairs):
    # Display conversion is linear 3-bit to 8-bit, not calibrated analog output.
    return [[((rb >> 4) & 7)*255//7, (g & 7)*255//7, (rb & 7)*255//7]
            for rb,g in register_pairs]


def png_indexed(width, height, pixels, palette, transparent=None):
    if len(pixels) != width*height or not 0 < len(palette) <= 256:
        raise ValueError('Invalid PNG dimensions/palette')
    if any(p < 0 or p >= len(palette) for p in pixels):
        raise ValueError('Pixel outside palette')
    if transparent is not None and not 0 <= transparent < len(palette):
        raise ValueError('Transparent index outside palette')
    def chunk(kind, payload):
        return struct.pack('>I',len(payload)) + kind + payload + struct.pack('>I',zlib.crc32(kind+payload)&0xffffffff)
    scan = b''.join(b'\0'+bytes(pixels[y*width:(y+1)*width]) for y in range(height))
    alpha = b'' if transparent is None else chunk(b'tRNS', bytes(0 if i == transparent else 255
                                                                for i in range(transparent + 1)))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,3,0,0,0)) +
            chunk(b'PLTE',bytes(v for color in palette for v in color)) + alpha +
            chunk(b'IDAT',zlib.compress(scan,9)) + chunk(b'IEND',b''))


def connection_index(room):
    if 0 <= room <= 125:
        return room
    if 208 <= room <= 227:
        return room - 82
    if 241 <= room <= 250:
        return room - 95
    return None
