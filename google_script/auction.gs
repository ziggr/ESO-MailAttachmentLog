// constants
COL_DONOR            = 1;
COL_TICKET_VALUE     = 2;
COL_PURCHASE_AMOUNT  = 3;
COL_BUYER            = 4;
COL_STATUS           = 5;
COL_ITEMS            = 6;
COL_LINKS            = 7;
COL_CT               = 7;

// If the frontmost sheet is not the "Auction" sheet, do nothing.
function ThrowIfNotAuctionSheet()
{
 var sheet = SpreadsheetApp.getActiveSheet()
 if (sheet.getName() != "Auction")
 {
   var msg = 'Only works on "Auction" sheet.'
   throw msg;
 }
}

// Split a single "Donated by @name  link1 link2 link3..." into an
// array of ["Donated by @name link1", "Donated by @name link2",
// "Donated by @name link3", ... ]

function SplitLinkText(link_text)
{
  var re_donate_links = /Donated by (@[^ :]+)/i;
  var t = re_donate_links.exec(link_text)
  var donor_name = t[1];

                // Split out the (usually multiple) links.
                // Note that split() here includes TWO elements per capture:
                // - the capture itself (what we want)
                // - the stuff before or after the capture (empty string we ignore)
                // So filter that out.
  var re_one_link     = /(\|H\d:item:[\d:]+\|h\|h)/;
  var split_link_arr  = link_text.split(re_one_link);
  var link_arr        = []
  for (var i = 1; i <= split_link_arr.length; ++i)
  {
    if (split_link_arr[i])
    {
      link_arr.push("Donated by " + donor_name + ": " + split_link_arr[i])
    }
  }

  return link_arr
}

// Split a single row into multiple, one for each link in its COL_LINKS text.
function SplitRow(row_index)
{
  var sheet      = SpreadsheetApp.getActiveSheet();
  var col_index  = COL_LINKS;
  var link_range = sheet.getRange(row_index, col_index);
  var link_text  = link_range.getDisplayValue();
  var link_arr   = SplitLinkText(link_text);
  if (link_arr.length <= 1)
  {
    throw "Only one item. Nothing to split."
  }
            // Make a hole
  var row_insert_ct = link_arr.length - 1;
  sheet.insertRowsAfter(row_index, row_insert_ct);

            // Duplicate original row to all new rows.
  var copy_range  = sheet.getRange(row_index,  1, 1, COL_CT);
  var paste_range = sheet.getRange(row_index + 1, 1, row_insert_ct, COL_CT);
  copy_range.copyTo(paste_range)

            // Split the item links across the original+new rows.
  for (var i = 0; i <= row_insert_ct; ++i)
  {
      var cell_range = sheet.getRange(row_index + i, COL_LINKS)
      cell_range.setValue(link_arr[i])
  }
}

// -- UI ------------------------------------------------------
function onOpen()
{
  var spreadsheet = SpreadsheetApp.getActive();
  var menu_items = [ { name: 'Split Row'
                     , functionName: 'UISplitRows'
                     }
                   , { name: 'Merge Rows'
                     , functionName: 'UIMergeRows'
                     }
                   ];
  spreadsheet.addMenu('ZZ', menu_items);
}

function UISplitRows()
{
  ThrowIfNotAuctionSheet();
  var sheet      = SpreadsheetApp.getActiveSheet();
  var sel_range  = sheet.getActiveRange();
  if (1 != sel_range.getNumRows()) throw "Can split only single rows." ;
  var row_index  = sel_range.getRowIndex();
  SplitRow(row_index)
}

function UIMergeRows()
{
  ThrowIfNotAuctionSheet()
}

