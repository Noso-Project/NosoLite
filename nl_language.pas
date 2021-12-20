unit nl_language;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;


Resourcestring
  //Error messages
  rsError0001 = 'Error: creating new wallet file-> %s';
  rsError0002 = 'Error: loading wallet from file-> %s';
  rsError0003 = 'FAILED';
  rsError0004 = 'Error: Saving wallet to disk-> %s';
  rsError0005 = 'Error: Disconnecting client-> %s';
  rsError0006 = 'Error: connecting node %s-> %s';
  rsError0007 = 'Error: Address already exists on wallet-> %s';
  rsError0008 = 'Error: Downloading summary from -> %s';
  rsError0009 = 'Error: Can not delete only address of the wallet';
  rsError0010 = 'Error: Invalid parameters for sending coins';

  // GUI interface
  rsGUI0001 = 'Address';
  rsGUI0002 = 'Incoming';
  rsGUI0003 = 'Outgoing';
  rsGUI0004 = 'Balance';
  rsGUI0005 = 'Host';
  rsGUI0006 = 'Block';
  rsGUI0007 = 'Pending';
  rsGUI0008 = 'Branch';
  rsGUI0009 = '%s NOSO';
  rsGUI0010 = 'Import from file';
  rsGUI0011 = '[%s] %s';
  rsGUI0012 = 'Added new wallet: %s';
  rsGUI0013 = 'Sumary downloaded: %d kb';
  rsGUI0014 = 'Destination';
  rsGUI0015 = 'Ammount';
  rsGUI0016 = 'Reference';

  // Dialogs
  rsDIA0001 = 'Import address keys';
  rsDIA0002 = 'Paste here the address keys';
  rsDIA0003 = 'Error: Invalid keys';

  // Explorer
  rsEXP0001 = 'Name';

implementation

END. // End unit

