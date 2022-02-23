unit nl_language;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;


Resourcestring
  //Error messages
  rsError0001 = 'Error: creating new wallet file-> %s';
  rsError0002 = 'Error: loading wallet from file-> %s';
  rsError0003 = '-Error-';
  rsError0004 = 'Error: Saving wallet to disk-> %s';
  rsError0005 = 'Error: Disconnecting client-> %s';
  rsError0006 = 'Error: connecting node %s-> %s';
  rsError0007 = 'Error: Address already exists on wallet-> %s';
  rsError0008 = 'Error: Downloading summary from -> %s';
  rsError0009 = 'Error: Can not delete only address of the wallet';
  rsError0010 = 'Error: Invalid parameters for sending coins';
  rsError0011 = 'Error: Invalid password for address %s';
  rsError0012 = 'Error: Insufficient funds';
  rsError0013 = 'Error: Can not generate certificates from locked addresses';
  rsError0014 = 'Error: Retrieving pendings -> %s';
  rsError0015 = 'Error: Sending order -> %s';

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
  rsGUI0017 = 'Downloading summary %s';
  rsGUI0018 = 'Masternodes';
  rsGUI0019 = 'MNs #';
  rsGUI0020 = 'Certificate for address : %s';
  rsGUI0021 = 'Processing...';
  rsGUI0022 = 'Send %s Noso to %s'+slinebreak+'Reference: %s';
  rsGUI0023 = 'Failed';
  rsGUI0024 = 'Successful: %s';
  rsGUI0025 = 'Noso total supply is %s millions';
  rsGUI0026 = 'Check certificate';
  rsGUI0027 = '%s verified %s ago';
  rsGUI0028 = 'Invalid certificate';
  rsGUI0029 = 'BestHash';
  // Dialogs
  rsDIA0001 = 'Import address keys';
  rsDIA0002 = 'Paste here the address keys';
  rsDIA0003 = 'Error: Invalid keys';
  rsDIA0004 = 'Password length must be 8 chars or more';
  rsDIA0005 = 'Passwords do not match';

  // Explorer
  rsEXP0001 = 'Name';

implementation

END. // End unit

