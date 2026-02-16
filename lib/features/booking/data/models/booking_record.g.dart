// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_record.dart';

class BookingRecordAdapter extends TypeAdapter<BookingRecord> {
  @override
  int get typeId => bookingRecordTypeId;

  @override
  BookingRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return BookingRecord(
      bookingId: fields[0] as String,
      hotelName: fields[1] as String,
      location: fields[2] as String,
      roomName: fields[3] as String,
      imageUrl: fields[4] as String,
      checkIn: fields[5] as DateTime,
      checkOut: fields[6] as DateTime,
      bookingStatus: fields[7] as String,
      confirmationNumber: fields[8] as String?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BookingRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.bookingId)
      ..writeByte(1)
      ..write(obj.hotelName)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.roomName)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.checkIn)
      ..writeByte(6)
      ..write(obj.checkOut)
      ..writeByte(7)
      ..write(obj.bookingStatus)
      ..writeByte(8)
      ..write(obj.confirmationNumber)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
